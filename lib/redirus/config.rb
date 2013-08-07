require 'yaml'

ROOT_PATH = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))

module Redirus
  class Config
    def initialize(path=nil)
      config_path = path || default_config_path

      if File.exists?(config_path)
        @config = YAML.load_file(config_path)
      else
        @config = {}
      end
    end

    def queue
      @config['queue'] || 'default'
    end

    def redis_url
      @config['redis_url'] || 'redis://localhost:6379'
    end

    def namespace
      @config['namespace'] || 'redirus'
    end

    def http_proxy_file
      config_file :http, :proxy, 'http_proxy.conf'
    end

    def http_upstream_file
      config_file :http, :upstream, 'http_upstream.conf'
    end

    def https_proxy_file
      config_file :https, :proxy, 'https_proxy.conf'
    end

    def https_upstream_file
      config_file :https, :upstream, 'http_upstream.conf'
    end

    def nginx_pid_file
      nginx_prop :pid, 'nginx.pid'
    end

    private

    def config_file(http_type, type, default)
      prop = nginx_prop http_type
      value = prop[type.to_s] if prop

      value || default
    end

    def nginx_prop(type, default=nil)
      value = @config['nginx'][type.to_s] if @config['nginx']
      value || default
    end

    def default_config_path
      File.join(ROOT_PATH, 'config.yml')
    end
  end
end