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
      nginx_prop :http_template, 'listen *:80;'
    end

    def https_template
      nginx_prop :https_template, %q[listen *:443 ssl;
ssl_certificate     /usr/share/ssl/certs/localhost/host.cert;
ssl_certificate_key /usr/share/ssl/certs/localhost/host.key;
]
    end

    def config_template
      nginx_prop :config_template, %q[#{upstream}

server {
  #{listen}

  server_name #{name}.localhost;
  server_tokens off;

  location / {
    proxy_pass http://#{upstream_name};
  }
}]
    end

    def allowed_properties
      nginx_prop :allowed_properties, []
    end

    private

    def nginx_prop(type, default=nil)
      value = @config['nginx'][type.to_s] if @config['nginx']
      value || default
    end

    def default_config_path
      File.join(ROOT_PATH, 'config.yml')
    end
  end
end