require 'pry-byebug'
require 'rake'
require 'rspec'
require 'txgh-queue'

require 'spec_helpers/test_backend'

RSpec.configure do |config|
end

TxghQueue::Backends.register('test-backend', TxghQueue::TestBackend)
