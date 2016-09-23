module TxghQueue
  autoload :Backends,      'txgh-queue/backends'
  autoload :Config,        'txgh-queue/config'
  autoload :Consumer,      'txgh-queue/consumer'
  autoload :ErrorHandlers, 'txgh-queue/error_handlers'
  autoload :Status,        'txgh-queue/status'
  autoload :Supervisor,    'txgh-queue/supervisor'
  autoload :Result,        'txgh-queue/result'

  Backends.register('sqs', TxghQueue::Backends::Sqs)
end
