require 'rubygems'
require 'sidekiq'

require_relative 'worker/add_proxy'
require_relative 'worker/rm_proxy'
require_relative 'worker'

Sidekiq.configure_server do |config|
  config.redis = { namespace: Redirus::Worker.config.namespace, url:Redirus::Worker.config.redis_url }
end