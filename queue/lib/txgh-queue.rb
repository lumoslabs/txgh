module TxghQueue
  autoload :Backends,      'txgh-queue/backends'
  autoload :Config,        'txgh-queue/config'
  autoload :Consumer,      'txgh-queue/consumer'
  autoload :ErrorBehavior, 'txgh-queue/error_behavior'
  autoload :Response,      'txgh-queue/response'

  Backends.register('sqs', TxghQueue::Backends::Sqs)
end
