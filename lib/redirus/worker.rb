require 'sidekiq'

module Redirus
  module Worker
    autoload :AddProxy, 'redirus/worker/add_proxy'
    autoload :RmProxy,  'redirus/worker/rm_proxy'
  end
end