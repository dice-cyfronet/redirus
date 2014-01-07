require 'sidekiq'

module Redirus
  module Worker
    class Proxy
      include Sidekiq::Worker

      def perform(*params)
        begin
          perform_action(*params)
          restart_nginx
        rescue Errno::EACCES
          $stderr << "Error: Cannot write to config files - continuing\n"
        rescue Errno::ENOENT
          $stderr << "Error: Trying to remove non existing config files - continuing\n"
        rescue Errno::ESRCH
          $stderr << "Warning: Nginx is dead - continuing\n"
        end
      end

      protected

      def perform_action(*params)
        #by default do nothing
      end

      def full_name(name, type)
        "#{name}_#{type}"
      end

      def config_file_path(name, type)
        File.join(config.configs_path, full_name(name, type))
      end

      def config
        @config ||= Redirus::Worker.config
      end

      def restart_nginx
        File.open(config.nginx_pid_file) do |file|
          pid = file.read.to_i
          Process.kill :SIGHUP, pid
        end
      end
    end
  end
end