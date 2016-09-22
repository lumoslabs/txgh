require 'spec_helper'

include TxghQueue

describe Response do
  describe '.retry_without_delay' do
    it 'returns the same object' do
      expect(Response.retry_without_delay.object_id).to eq(
        Response.retry_without_delay.object_id
      )
    end
  end

  describe '.retry_with_delay' do
    it 'returns the same object' do
      expect(Response.retry_with_delay.object_id).to eq(
        Response.retry_with_delay.object_id
      )
    end
  end

  describe '.fail' do
    it 'returns the same object' do
      expect(Response.fail.object_id).to eq(Response.fail.object_id)
    end
  end

  describe '.ok' do
    it 'returns the same object' do
      expect(Response.ok.object_id).to eq(Response.ok.object_id)
    end
  end

  describe '#retry_without_delay?' do
    it 'returns true if the response matches, false otherwise' do
      expect(Response.retry_without_delay.retry_without_delay?).to eq(true)
      expect(Response.ok.retry_without_delay?).to eq(false)
    end
  end

  describe '#retry_with_delay?' do
    it 'returns true if the response matches, false otherwise' do
      expect(Response.retry_with_delay.retry_with_delay?).to eq(true)
      expect(Response.ok.retry_with_delay?).to eq(false)
    end
  end

  describe '#fail?' do
    it 'returns true if the response matches, false otherwise' do
      expect(Response.fail.fail?).to eq(true)
      expect(Response.ok.fail?).to eq(false)
    end
  end

  describe '#ok?' do
    it 'returns true if the response matches, false otherwise' do
      expect(Response.ok.ok?).to eq(true)
      expect(Response.fail.ok?).to eq(false)
    end
  end
end
