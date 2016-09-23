require 'json'

module TxghQueue
  module Backends
    module Sqs
      class Consumer < ::TxghQueue::Consumer
        def work
          params = { message_attribute_names: %w(retry_sequence) }

          loop do
            queues.each do |queue|
              queue.receive_message(params).messages.each do |message|
                logger.info("Received message from #{queue.name}, id: #{message.message_id}")
                work_on(message, queue)
              end
            end
          end
        end

        private

        def work_on(message, queue)
          payload = JSON.parse(message.body)
          logger.info("Processing #{message.message_id}")
          logger.info("Payload: #{payload.inspect}")
          result = process(payload)
          logger.info("Finished processing #{message.message_id}, result: #{result}")

          if result.error?
            Txgh.events.publish_error(e, {
              raise_if_no_subscribers: false,
              params: {
                payload: payload,
                message_id: message.message_id,
                queue: queue.name
              }
            })
          end

          return do_ok(message, queue) if result.ok?
          return do_retry(message, queue, result) if result.retry?
          return do_fail(message, queue) if result.fail?
        end

        def do_ok(message, queue)
          delete(message, queue)
          logger.info("Deleted #{message.message_id}")
        end

        def do_retry(message, queue, result)
          RetryLogic.ingest(message, result) do |logic|
            logic.on_retry do |sqs_retry_params, delay_seconds|
              logger.info("Retrying #{message.message_id} with #{delay_seconds} second delay")
              new_message = queue.send_message(message.body, sqs_retry_params)
              logger.info("Re-enqueued as #{new_message.message_id}")
              delete(message, queue)
              logger.info("Deleted original #{message.message_id}")
            end

            logic.on_retries_exceeded do
              logger.info("Message #{message.message_id} has exceeded allowed retries.")
            end
          end
        end

        def do_fail(message, queue)
          # don't do anything - just let the message expire and get sent to the
          # dead letter queue
        end

        def delete(message, queue)
          queue.delete_message(message.receipt_handle)
        end
      end
    end
  end
end
