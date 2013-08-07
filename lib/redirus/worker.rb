require 'sidekiq'

require_relative 'config'

module Redirus
  module Worker
    def self.config
      @@config ||= Redirus::Config.new @config_path
    end

    def self.config_path
      @@config_path = config_path
      @@config = nil
    end
  end
end