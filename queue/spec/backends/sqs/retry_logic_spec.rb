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
        retry_sequence: {
          string_value: described_class::OVERALL_MAX_RETRIES.times.map do
            { status: 'retry_without_delay' }
          end.to_json
        }
      )
    end

    describe '#retries_exceeded?' do
      it 'indicates retries have been exceeded' do
        expect(logic.retries_exceeded?).to eq(true)
      end
    end

    describe '#retry?' do
      it 'indicates another retry should not be attempted' do
        expect(logic.retry?).to eq(false)
      end
    end

    describe '#next_delay_seconds' do
      it 'indicates a delay of zero seconds' do
        expect(logic.next_delay_seconds).to eq(0)
      end
    end
  end

  context 'with a run of no-delay retries' do
    let(:logic) { described_class.new(message_attributes, current_status) }
    let(:current_status) { Status.retry_without_delay }
    let(:message) { SqsTestMessage.new('abc123', '{}', message_attributes.to_h) }
    let(:message_attributes) do
      Sqs::MessageAttributes.from_h(
        retry_sequence: {
          string_value: [
            { status: 'retry_without_delay' },
            { status: 'retry_without_delay' },
            { status: 'retry_without_delay' }
          ].to_json
        }
      )
    end

    describe '#retries_exceeded?' do
      it 'indicates retries have not been exceeded' do
        expect(logic.retries_exceeded?).to eq(false)
      end
    end

    describe '#retry?' do
      it 'indicates another retry may be attempted' do
        expect(logic.retry?).to eq(true)
      end
    end

    describe '#next_delay_seconds' do
      it 'indicates a delay of zero seconds' do
        expect(logic.next_delay_seconds).to eq(0)
      end
    end

    context 'and a delayed current status' do
      let(:current_status) { Status.retry_with_delay }

      describe '#next_delay_seconds' do
        it 'indicates a first-stage delay' do
          expect(logic.next_delay_seconds).to(
            eq(described_class::DELAY_INTERVALS.first)
          )
        end
      end
    end
  end
end
