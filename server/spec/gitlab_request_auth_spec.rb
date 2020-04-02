require 'spec_helper'
require 'rack'

describe TxghServer::GitlabRequestAuth do
  let(:secret) { 'abc123' }

  describe '.authentic_request?' do
    it 'returns true if the request is signed correctly' do
      request = Rack::Request.new(
        described_class::RACK_HEADER => secret
      )

      authentic = described_class.authentic_request?(request, secret)
      expect(authentic).to eq(true)
    end

    it 'returns false if the request is not signed correctly' do
      request = Rack::Request.new(
        described_class::RACK_HEADER => 'incorrect'
      )

      authentic = described_class.authentic_request?(request, secret)
      expect(authentic).to eq(false)
    end
  end
end
