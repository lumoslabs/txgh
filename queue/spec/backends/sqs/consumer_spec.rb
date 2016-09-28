require 'spec_helper'
require 'spec_helpers/sqs/sqs_test_message'

include TxghQueue
include TxghQueue::Backends

describe Sqs::Consumer, auto_configure: true do
  let(:queue_config) { sqs_queue_config }
  let(:queues) { Sqs::Config.queues }
  let(:logger) { NilLogger.new }
  let(:message) { SqsTestMessage.new('abc123', '{}') }
  let(:consumer) { described_class.new(queues, logger) }

  it 'executes one job in each queue' do
    queues.each do |queue|
      job = double(:Job)
      expect(queue).to receive(:receive_message).and_return(message.to_bundle)
      expect(job).to receive(:complete)
      expect(Sqs::Job).to(
        receive(:new).with(message, queue, logger).and_return(job)
      )
    end

    consumer.work
  end
end
