require 'sidekiq'

module Redirus
  autoload :Version,        'redirus/version'
  autoload :Config,         'redirus/config'
  autoload :Proxy,          'redirus/proxy'
  autoload :Utils,          'redirus/utils'
  autoload :CLI,            'redirus/cli'
  autoload :ServerCLI,      'redirus/server_cli'

  def self.config
    @@config ||= Redirus::Config.new(config_path)
  end

  def self.config_path
    @@config_path ||= ARGV[0] || 'config.yml'
  end

  def self.config_path=(path)
    @@config_path = path
    @@config = nil
  end
end

require 'redirus/worker'
