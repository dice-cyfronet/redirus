require 'sidekiq'

module Redirus
  class Proxy
    include Sidekiq::Worker

    def perform(*params)
      perform_action(*params)
      restart_nginx
    rescue Errno::EACCES => e
      error('Error: Cannot write to config files - continuing', e)
    rescue Errno::ENOENT => e
      error('Error: Remove non existing config files - continuing', e)
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
    rescue Errno::ENOENT => e
      error('Error: Nginx pid file does not exist - continuing', e)
    rescue Errno::ESRCH => e
      error('Warning: Nginx is dead - continuing', e)
    end

    def error(msg, e)
      $stderr << "#{msg}\n  - #{e}\n"
    end
  end
end