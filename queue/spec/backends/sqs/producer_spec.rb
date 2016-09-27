require 'spec_helper'

include TxghQueue::Backends

describe Sqs::Producer, auto_configure: true do
  let(:queue_config) { sqs_queue_config }
  let(:logger) { NilLogger.new }
  let(:queue) { TxghQueue::Backends::Sqs::Config.get_queue('test-queue') }
  let(:producer) { described_class.new(queue, logger) }

  describe '#enqueue' do
    it 'sends a message to the SQS queue' do
      payload = { abc: 'def' }
      message = double(:Message, message_id: 123)

      expect(queue).to(
        receive(:send_message)
          .with(payload.to_json, foo: 'bar')
          .and_return(message)
      )

      producer.enqueue(payload, foo: 'bar')
    end
  end
end
