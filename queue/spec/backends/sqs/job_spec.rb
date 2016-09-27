require 'spec_helper'
require 'spec_helpers/sqs/sqs_test_message'

include TxghQueue
include TxghQueue::Backends

describe Sqs::Job, auto_configure: true do
  let(:queue_config) { sqs_queue_config }
  let(:queue) { Sqs::Config.queues.first }
  let(:failure_queue) { Sqs::Config.failure_queue }
  let(:logger) { NilLogger.new }
  let(:body) { { 'foo' => 'bar' } }
  let(:message) { SqsTestMessage.new('123abc', body.to_json) }
  let(:job) { described_class.new(message, queue, logger) }

  describe '#complete' do
    it 'processes a single job and deletes the message' do
      result = Result.new(Status.ok, TxghServer::Response.new(200, 'Ok'))
      expect(queue).to receive(:delete_message).with(message.receipt_handle)
      expect(job).to receive(:process).with(body).and_return(result)
      job.complete
    end

    context 'retries' do
      let(:response) { TxghServer::Response.new(502, 'Bad gateway') }
      let(:new_message) { SqsTestMessage.new('456def', body.to_json) }

      before(:each) do
        # should delete the old message
        expect(queue).to receive(:delete_message).with(message.receipt_handle)
      end

      it 're-enqueues the message if told to retry' do
        response = TxghServer::Response.new(502, 'Bad gateway')
        result = Result.new(Status.retry_without_delay, response)
        expect(job).to receive(:process).with(body).and_return(result)

        # this call to send_message signifies a retry
        expect(queue).to receive(:send_message) do |body, retry_params|
          sequence = retry_params[:message_attributes][:retry_sequence][:string_value]
          sequence = JSON.parse(sequence).map { |elem| elem['status'] }
          expect(sequence).to eq(%w(retry_without_delay))
          new_message
        end

        job.complete
      end

      it 're-enqueues with delay if told to do so' do
        response = TxghServer::Response.new(502, 'Bad gateway')
        result = Result.new(Status.retry_with_delay, response)
        expect(job).to receive(:process).with(body).and_return(result)

        # this call to send_message signifies a retry
        expect(queue).to receive(:send_message) do |body, retry_params|
          sequence = retry_params[:message_attributes][:retry_sequence][:string_value]
          sequence = JSON.parse(sequence).map { |elem| elem['status'] }
          expect(sequence).to eq(%w(retry_with_delay))

          expect(retry_params[:delay_seconds]).to eq(
            Sqs::RetryLogic::DELAY_INTERVALS.first
          )

          new_message
        end

        job.complete
      end
    end

    it 'sends the message to the failure queue' do
      result = Result.new(Status.fail, TxghServer::Response.new(500, '💩'))
      expect(job).to receive(:process).with(body).and_return(result)
      expect(queue).to receive(:delete_message).with(message.receipt_handle)
      expect(failure_queue).to receive(:send_message).with(body.to_json, anything)
      job.complete
    end

    it 'reports errors to the event system' do
      error = StandardError.new('jelly beans')
      result = Result.new(Status.fail, error)
      expect(job).to receive(:process).and_return(result)
      expect(queue).to receive(:delete_message).with(message.receipt_handle)
      expect(failure_queue).to receive(:send_message)

      expect(Txgh.events).to receive(:publish_error) do |e, options|
        expect(e).to eq(error)
        expect(options[:params]).to eq(
          payload: body, message_id: message.message_id, queue: queue.name
        )
      end

      job.complete
    end
  end
end
