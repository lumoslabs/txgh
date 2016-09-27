require 'spec_helper'
require 'spec_helpers/sqs/sqs_test_message'

include TxghQueue
include TxghQueue::Backends

describe Sqs::RetryLogic do
  context 'with overall retries exceeded' do
    let(:logic) { described_class.new(message_attributes, current_status) }
    let(:current_status) { Status.retry_without_delay }
    let(:message) { SqsTestMessage.new('abc123', '{}', message_attributes.to_h) }
    let(:message_attributes) do
      Sqs::MessageAttributes.from_h(
        retry_sequence: described_class::OVERALL_MAX_RETRIES.times.map do
          { status: 'retry_without_delay' }
        end
      )
    end

    describe '#retries_exceeded?' do
      it 'returns true' do
        expect(logic.retries_exceeded?).to eq(true)
      end
    end
  end
end
