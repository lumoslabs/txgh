module TxghQueue
  module ErrorHandlers
    autoload :Github,         'txgh-queue/error_handlers/github'
    autoload :Gitlab,         'txgh-queue/error_handlers/gitlab'
    autoload :NetworkErrors,  'txgh-queue/error_handlers/network_errors'
    autoload :ServerResponse, 'txgh-queue/error_handlers/server_response'
    autoload :StandardErrors, 'txgh-queue/error_handlers/standard_errors'
    autoload :Transifex,      'txgh-queue/error_handlers/transifex'
    autoload :TxghErrors,     'txgh-queue/error_handlers/txgh_errors'
  end
end
