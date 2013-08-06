require 'sidekiq'

module Redirus
  module Worker
    class Proxy
      include Sidekiq::Worker

      def perform(proxies=[], properties=[])
        proxy_config = proxy_config(proxies, properties)

        begin
          update_http  proxy_config
          update_https proxy_config
          restart_nginx
        rescue Errno::EACCES
          $stderr << "Error: Cannot write to config files\n"
          raise
        rescue Errno::ESRCH
          $stderr << "Warning: Nginx is dead - continuing\n"
        end
      end

      def self.generator
        @@generator || Redirus::Worker::NginxConfigGenerator
      end

      # XXX: is it possible to use something like cattr_writer?
      def self.generator=(generator)
        @@generator = generator
      end

      private

      def config
        @config = Redirus::Worker.config
      end

      def proxy_config(proxies, properties)
        self.class.generator.new(proxies, properties).generate
      end

      def update_http(http_proxy_config)
        write_proxy_config config.http_proxy_file, config.http_upstream_file, http_proxy_config[:http]
      end

      def update_https(https_proxy_config)
        write_proxy_config config.https_proxy_file, config.https_upstream_file, https_proxy_config[:https]
      end

      def restart_nginx
        File.open(config.nginx_pid_file) do |file|
          pid = file.read.to_i
          Process.kill :SIGHUP, pid
        end
      end

      def write_proxy_config(proxy_file, upstream_file, config)
        File.open(proxy_file, 'w') { |file| file.write config[:proxy] }
        File.open(upstream_file, 'w') { |file| file.write config[:upstream] }
      end
    end
  end
end