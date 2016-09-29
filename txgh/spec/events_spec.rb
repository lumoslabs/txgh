require 'spec_helper'

include Txgh

describe Events do
  let(:events) { Events.new }

  describe '#subscribe and #channels' do
    it "adds a channel if it doesn't already exist" do
      expect(events.channels).to be_empty
      events.subscribe('foo.bar')
      expect(events.channels).to eq(['foo.bar'])
    end

    it 'adds the proc to the list of callbacks for the channel' do
      events.subscribe('foo.bar') { 'baz' }
      expect(events.channel_hash['foo.bar'].first.call).to eq('baz')
    end
  end

  describe '#publish' do
    it 'notifies all subscribers' do
      received = []
      events.subscribe('foo.bar') { |arg| received << "foo.bar #{arg}" }
      events.subscribe('foo.bar') { |arg| received << "foo.bar2 #{arg}" }
      events.publish('foo.bar', 'baz')
      expect(received).to eq([
        'foo.bar baz', 'foo.bar2 baz'
      ])
    end

    it 'publishes errors through a special errors channel' do
      errors = []
      events.subscribe('errors') { |e| errors << e }
      events.subscribe('foo.bar') { raise 'jelly beans' }
      expect { events.publish('foo.bar') }.to_not raise_error
      expect(errors.first.message).to eq('jelly beans')
    end

    it 'raises errors if there are no error subscribers' do
      events.subscribe('foo.bar') { raise 'jelly beans' }
      expect { events.publish('foo.bar') }.to raise_error('jelly beans')
    end
  end

  describe '#publish_error' do
    it 'publishes the given error over the error channel' do
      errors = []
      events.subscribe('errors') { |e| errors << e }
      events.publish_error(begin; raise 'foo'; rescue => e; e; end)
      expect(errors.size).to eq(1)
      expect(errors.first.message).to eq('foo')
    end

    it 'includes additional params' do
      errors = []
      events.subscribe('errors') { |e, params| errors << { error: e, params: params } }
      events.publish_error(begin; raise 'foo'; rescue => e; e; end, params: { foo: 'bar' })
      expect(errors.size).to eq(1)

      error = errors.first
      expect(error[:error].message).to eq('foo')
      expect(error[:params]).to eq(foo: 'bar')
    end

    it 'raises errors if no error subscribers are configured' do
      expect { events.publish_error(StandardError.new) }.to raise_error(StandardError)
    end

    it 'does not raise errors if specifically asked not to when no error subscribers are configured' do
      expect { events.publish_error(StandardError.new, raise_if_no_subscribers: false) }.to_not raise_error
    end
  end
end
