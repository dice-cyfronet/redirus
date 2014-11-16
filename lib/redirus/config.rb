require 'yaml'

ROOT_PATH = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))

module Redirus
  class Config
    def initialize(path=nil)
      if File.exists?(path)
        @config = YAML.load_file(path)
      else
        @config = {}
      end
    end

    def queues
      @config['queues'] || ['default']
    end

    def redis_url
      @config['redis_url'] || 'redis://localhost:6379'
    end

    def namespace
      @config['namespace'] || 'redirus'
    end

    def nginx_pid_file
      nginx_prop :pid, 'nginx.pid'
    end

    def configs_path
      nginx_prop :configs_path, 'sites-enabled'
    end

    def http_template
      nginx_prop :http_template, 'http.conf.erb'
    end

    def https_template
      nginx_prop :https_template, 'https.conf.erb'
    end

    def allowed_properties
      nginx_prop :allowed_properties, []
    end

    private

    def nginx_prop(type, default=nil)
      value = @config['nginx'][type.to_s] if @config['nginx']
      value || default
    end
  end
end
