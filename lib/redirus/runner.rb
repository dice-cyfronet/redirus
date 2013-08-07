require 'rubygems'
require 'sidekiq'

require_relative 'worker/proxy'
require_relative 'worker'

Sidekiq.configure_server do |config|
  config.redis = { namespace: Redirus::Worker.config.namespace, url:Redirus::Worker.config.redis_url, queue:  Redirus::Worker.config.queue }
end