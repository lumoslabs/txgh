require 'json'

module TxghQueue
  module Backends
    module Sqs
      class RetriesExceededError < StandardError; end

      class RetryLogic
        SEQUENTIAL_MAX_RETRIES = 5
        OVERALL_MAX_RETRIES = 15

        # SQS max is 15 minutes, or 900 seconds
        DELAY_INTERVALS = [16, 32, 64, 128, 256, 512, 900]

        attr_reader :message_attributes, :current_status

        def initialize(message_attributes, current_status)
          @message_attributes = message_attributes.dup
          @current_status = current_status
        end

        def retry?
          retry_with_delay? || retry_without_delay?
        end

        def retries_exceeded?
          max_overall_retries_exceeded? ||
            max_sequential_retries_exceeded? ||
            max_sequential_delays_exceeded?
        end

        def next_delay_seconds
          raise RetriesExceededError unless retry?
          return 0 unless retry_with_delay?
          DELAY_INTERVALS[[current_sequence.size - 1, 0].max]
        end

        def sqs_retry_params
          if retry_without_delay?
            sqs_params_without_delay
          elsif retry_with_delay?
            sqs_params_with_delay
          else
            raise RetriesExceededError
          end
        end

        private

        def retry_with_delay?
          return false if max_overall_retries_exceeded?
          return false unless current_status.retry_with_delay?
          !max_sequential_delays_exceeded?
        end

        def retry_without_delay?
          return false if max_overall_retries_exceeded?
          return false unless current_status.retry_without_delay?
          !max_sequential_retries_exceeded?
        end

        def sqs_params_without_delay
          { message_attributes: message_attributes.to_h }
        end

        def sqs_params_with_delay
          sqs_params_without_delay.merge(delay_seconds: next_delay_seconds)
        end

        def max_overall_retries_exceeded?
          history_sequence.size >= OVERALL_MAX_RETRIES
        end

        def max_sequential_delays_exceeded?
          delay_sequence_will_continue? && current_sequence.size >= DELAY_INTERVALS.size
        end

        def max_sequential_retries_exceeded?
          retry_sequence_will_continue? && current_sequence.size >= SEQUENTIAL_MAX_RETRIES
        end

        def retry_sequence_will_continue?
          current_status.status == last_status &&
            current_status.retry_without_delay?
        end

        def delay_sequence_will_continue?
          current_status.status == last_status &&
            current_status.retry_with_delay?
        end

        def last_status
          rt = current_sequence.last
          rt.to_sym if rt
        end

        def current_sequence
          if sequence = partitioned_history_sequence.last
            if last_elem = sequence.last
              if current_status.status.to_s == last_elem
                return sequence
              end
            end
          end

          []
        end

        def partitioned_history_sequence
          @partitioned_history_sequence ||= history_sequence.partition
        end

        def history_sequence
          message_attributes.history_sequence
        end
      end
    end
  end
end
