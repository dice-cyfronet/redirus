require 'sidekiq'

module Redirus
  module Worker
    autoload :AddProxy, 'redirus/worker/add_proxy'
    autoload :RmProxy,  'redirus/worker/rm_proxy'
  end
end

Sidekiq.configure_server do |config|
  config.redis = {
    namespace: Redirus.config.namespace,
    url: Redirus.config.redis_url
  }
end

Sidekiq.configure_client do |c|
  c.redis = {
    namespace: Redirus.config.namespace,
    url: Redirus.config.redis_url
  }
end