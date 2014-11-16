require 'sidekiq'

module Redirus
  class Proxy
    include Sidekiq::Worker

    def perform(*params)
      begin
        perform_action(*params)
        restart_nginx
      rescue Errno::EACCES => e
        $stderr << "Error: Cannot write to config files - continuing\n"
        $stderr << "#{e}\n"
      rescue Errno::ENOENT => e
        $stderr << "Error: Trying to remove non existing config files - continuing\n"
        $stderr << "#{e}\n"
      rescue Errno::ESRCH => e
        $stderr << "Warning: Nginx is dead - continuing\n"
        $stderr << "#{e}\n"
      end
    end

    protected

    def perform_action(*params)
      #by default do nothing
    end

    private

    def restart_nginx
      File.open(Redirus.config.nginx_pid_file) do |file|
        pid = file.read.to_i
        Process.kill :SIGHUP, pid
      end
    end
  end
end