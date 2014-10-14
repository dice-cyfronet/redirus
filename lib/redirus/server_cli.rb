require 'optparse'
require 'singleton'
require 'sidekiq/cli'

module Redirus
  class ServerCLI
    include Singleton

    attr_reader :options

    def parse(args = ARGV)
      init_options(args)
      validate!
    end

    def run
      sidekiq_cli = Sidekiq::CLI.instance
      args = queues + [
        '-c', '1',
        '-r', runner_path,
        options[:config_path]
      ]

      sidekiq_cli.parse(args)
      sidekiq_cli.run
    end

    private

    def queues
      Redirus.config.queues.inject([]) do |arr, q|
        arr << '-q'
        arr << q
      end
    end

    def runner_path
      module_path = File.expand_path(File.join(File.dirname(__FILE__), '..'))
      File.join(module_path, 'redirus.rb')
    end

    def init_options(args)
      opts = parse_options(args)
      opts[:config_path] ||= 'config.yml'

      Redirus.config_path = opts[:config_path]

      @options = opts
    end

    def parse_options(args)
      opts = {}

      OptionParser.new do |o|
        o.banner = 'Usage: redirus [options]'

        o.on('-c',
             '--configuration PATH',
             'Yaml redirus configuration path') do |arg|
          opts[:config_path] = arg
        end

        o.on_tail('-h', '--help', 'Show this message') do
          puts opts
          exit
        end
      end.parse!

      opts
    end

    def validate!
      unless File.exist?(options[:config_path])
        puts "ERROR: Configuration file #{options[:config_path]} does not exist"
        exit(1)
      end
    end
  end
end