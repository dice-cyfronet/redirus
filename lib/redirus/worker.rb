require 'sidekiq'

require_relative 'config'
require_relative 'proxy'

config = Redirus::Config.new
Sidekiq.configure_server do |c|
  c.redis = { :namespace => config.namespace, :url => config.redis_url }
end
