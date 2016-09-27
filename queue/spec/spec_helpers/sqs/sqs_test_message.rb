require 'securerandom'

class SqsTestMessage
  attr_reader :message_id, :body, :message_attributes
  attr_reader :receipt_handle

  def initialize(message_id, body, message_attributes = {})
    @message_id = message_id
    @body = body
    @message_attributes = message_attributes
    @receipt_handle = SecureRandom.hex
  end

  def to_bundle
    SqsTestMessageBundle.new([self])
  end
end

class SqsTestMessageBundle
  attr_reader :messages

  def initialize(messages)
    @messages = messages
  end
end
