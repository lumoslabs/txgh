module TxghQueue
  module Backends
    module Sqs
      class RetryLogic
        SEQUENTIAL_MAX_RETRIES = 5
        OVERALL_MAX_RETRIES = 15

        # SQS max is 15 minutes, or 900 seconds
        DELAY_INTERVALS = [16, 32, 64, 128, 256, 512, 900]

        class << self
          def ingest(message, current_try_response)
            yield new(message, current_try_response)
          end
        end

        attr_reader :message, :current_try_response

        def initialize(message, current_try_response)
          @message = message
          @current_try_response = current_try_response
        end

        def on_retry
          yield(sqs_retry_params, next_delay_seconds) if retry?
        end

        def on_retries_exceeded
          yield if retries_exceeded?
        end

        private

        def retries_exceeded?
          max_overall_retries_exceeded? ||
            max_sequential_retries_exceeded? ||
            max_sequential_delays_exceeded?
        end

        def sqs_retry_params
          if retry_without_delay?
            sqs_params_without_delay
          elsif retry_with_delay?
            sqs_params_with_delay
          end
        end

        def next_delay_seconds
          return 0 unless retry_with_delay?
          DELAY_INTERVALS[current_sequence.size]
        end

        def retry?
          retry_with_delay? || retry_without_delay?
        end

        def retry_with_delay?
          return false if max_overall_retries_exceeded?
          return false unless current_try_response.retry_with_delay?
          !max_sequential_delays_exceeded?
        end

        def retry_without_delay?
          return false if max_overall_retries_exceeded?
          return false unless current_try_response.retry_without_delay?
          !max_sequential_retries_exceeded?
        end

        def sqs_params_without_delay
          {
            message_attributes: {
              retry_sequence: {
                string_value: (retry_sequence + [current_try_response.to_s]).join(' '),
                data_type: 'String'
              }
            }
          }
        end

        def sqs_params_with_delay
          sqs_params_without_delay.merge(delay_seconds: 5) # next_delay_seconds)
        end

        def max_overall_retries_exceeded?
          retry_sequence.size >= OVERALL_MAX_RETRIES
        end

        def max_sequential_delays_exceeded?
          delay_sequence_will_continue? && current_sequence.size >= DELAY_INTERVALS.size
        end

        def max_sequential_retries_exceeded?
          retry_sequence_will_continue? && current_sequence.size >= SEQUENTIAL_MAX_RETRIES
        end

        def retry_sequence_will_continue?
          current_try_response.retry_type == last_retry_type &&
            current_try_response.retry_without_delay?
        end

        def delay_sequence_will_continue?
          current_try_response.retry_type == last_retry_type &&
            current_try_response.retry_with_delay?
        end

        def last_retry_type
          if rt = current_sequence.last
            rt.to_sym
          end
        end

        def current_sequence
          if sequence = partitioned_retry_sequence.last
            if last_elem = sequence.last
              if current_try_response.retry_type.to_s == last_elem
                return sequence
              end
            end
          end

          []
        end

        def partitioned_retry_sequence
          @partitioned_retry_sequence ||= begin
            retry_sequence.each_with_object([]) do |elem, ret|
              if ret.last && ret.last.last == elem
                ret.last << elem
              else
                ret << [elem]
              end
            end
          end
        end

        def retry_sequence
          @retry_sequence ||= begin
            if attribute = message.message_attributes['retry_sequence']
              attribute.string_value.split(' ')
            else
              []
            end
          end
        end
      end
    end
  end
end
