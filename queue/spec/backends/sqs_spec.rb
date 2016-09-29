require 'spec_helper'

include TxghQueue::Backends

describe Sqs, auto_configure: true do
  let(:queue_config) { sqs_queue_config }

  describe '.producer_for' do
    it 'looks up the queues for the given event and returns a producer object' do
      producer = described_class.producer_for('a')
      expect(producer).to be_a(Sqs::Producer)
      expect(producer.queues.size).to eq(1)
      expect(producer.queues.first).to be_a(Sqs::Queue)
      expect(producer.queues.first.name).to eq('test-queue')
    end
  end

  describe '.consumer_for' do
    it 'looks up the queue for the given event and returns a consumer object' do
      consumer = described_class.consumer_for('b')
      expect(consumer).to be_a(Sqs::Consumer)
      expect(consumer.queues.size).to eq(1)
      expect(consumer.queues.first).to be_a(Sqs::Queue)
      expect(consumer.queues.first.name).to eq('test-queue')
    end

    it 'handles the case if the event matches multiple queues' do
      consumer = described_class.consumer_for('c')
      expect(consumer.queues.size).to eq(2)
      expect(consumer.queues.map(&:name).sort).to eq(%w(test-queue test-queue-2))
    end
  end
end
