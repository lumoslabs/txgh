$:.unshift(File.dirname(__FILE__))
$:.unshift(File.join(File.dirname(__FILE__), 'lib'))

require 'txgh'

map '/' do
  use Txgh::Application
  use Txgh::Triggers
  run Sinatra::Base
end

map '/hooks' do
  use Txgh::Hooks
  run Sinatra::Base
end
