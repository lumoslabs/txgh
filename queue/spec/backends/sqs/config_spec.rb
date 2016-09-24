require 'spec_helper'

include TxghQueue::Backends

describe Sqs::Config, auto_configure: true do
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

  describe '.queues' do
    it 'lists all queues' do
      queues = described_class.queues
      queues.each { |q| expect(q).to be_a(Sqs::Queue) }
      expect(queues.map(&:name).sort).to eq(%w(test-queue test-queue-2))
    end
  end

  describe '.get_queue' do
    it 'pulls out a single queue object' do
      queue = described_class.get_queue('test-queue')
      expect(queue).to be_a(Sqs::Queue)
      expect(queue.name).to eq('test-queue')
    end
  end
end
