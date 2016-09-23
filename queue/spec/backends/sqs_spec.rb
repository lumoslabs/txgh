require 'spec_helper'

include TxghQueue::Backends

describe Sqs, auto_configure: true do
  let(:queue_config) do
    {
      backend: 'sqs',
      options: {
        queues: [
          { name: 'test-queue', region: 'us-east-1' },
          { name: 'test-queue-2', region: 'us-west-1' }
        ]
      }
    }
  end

  describe '.producer_for' do
    it 'looks up the queue and returns a producer object' do
      producer = described_class.producer_for('test-queue')
      expect(producer).to be_a(Sqs::Producer)
      expect(producer.queue).to be_a(Sqs::Queue)
      expect(producer.queue.name).to eq('test-queue')
    end
  end

  describe '.consumer_for' do
    it 'looks up the queue and returns a consumer object' do
      consumer = described_class.consumer_for('test-queue')
      expect(consumer).to be_a(Sqs::Consumer)
      expect(consumer.queues.size).to eq(1)
      expect(consumer.queues.first).to be_a(Sqs::Queue)
      expect(consumer.queues.first.name).to eq('test-queue')
    end

    it 'looks up multiple queues' do
      consumer = described_class.consumer_for(%w(test-queue test-queue-2))
      expect(consumer.queues.size).to eq(2)
      expect(consumer.queues.map(&:name).sort).to eq(%w(test-queue test-queue-2))
    end
  end
end
