require 'optparse'
require 'singleton'

module Redirus
  module Cli
    class Client
      include Singleton

      attr_reader :options

      def parse(args = ARGV)
        init_options(args)
        validate!
      end

      def run
        Redirus.config_path = options[:config_path]
        init_sidekiq

        add? ? add : rm
      end

      private

      def init_sidekiq
        Sidekiq.configure_client do |c|
          c.redis = {
            namespace: Redirus.config.namespace,
            url: Redirus.config.redis_url
          }
        end
      end

      def init_options(args)
        opts = parse_options(args)
        opts[:config_path] ||= 'config.yml'

        Redirus.config_path = opts[:config_path]

        @options = defaults.merge(opts)
      end

      def parse_options(args)
        opts = {}

        parser = OptionParser.new do |o|
          o.on('-c', '--configuration PATH', 'Configuration path') do |arg|
            opts[:config_path] = arg
          end

          o.on('-a',
               '--action TYPE', [:add, :rm],
               'Action type (add, rm)') do |arg|
            opts[:action] = arg
          end

          o.on('-q', '--queue NAME', 'Queue name') do |arg|
            opts[:queue] = arg
          end

          o.on('-t',
               '--type TYPE',
               [:http, :https],
               'Rediraction type') do |arg|
            opts[:type] = arg
          end

          o.on('-l',
               '--location-property LIST',
               Array,
               'List of location properties (e.g. prop1,prop2)') do |arg|
            opts[:location_properties] = arg
          end

          o.on('-o',
               '--options MAP',
               Array,
               'Option map (e.g. key1:value1,key2:value2)') do |arg|
            opts[:options] = to_hsh(arg)
          end

          o.on_tail('-h', '--help', 'Show this message') do
            puts o
            exit
          end

          o.on_tail('-v', '--version', 'Show version') do
            puts "Redirus #{Redirus::VERSION}"
            exit
          end
        end

        parser.banner = 'redirus-client [options] name '\
                        '[upstream1,upstream2,...]'

        parser.parse!(args)

        opts[:name] = args.shift

        upstreams_str = args.shift
        opts[:upstreams] = upstreams_str.split(',') if upstreams_str

        opts
      end

      def to_hsh(array)
        array.inject({}) do |hsh, item|
          kv = item.split(':')
          if kv.size >= 2
            hsh[kv[0]] = kv[1]
          end
          hsh
        end
      end

      def defaults
        {
          config_path: 'config.yml',
          type: :http,
          action: :add,
          location_properties: [],
          options: {},
          queue: Redirus.config.queues.first
        }
      end

      def validate!
        unless File.exist?(options[:config_path])
          puts "ERROR: Configuration file #{options[:config_path]} "\
               'does not exist'
          exit(1)
        end

        unless options[:name]
          puts 'ERROR: Redirection name is not set'
          exit(1)
        end

        if add?
          if options[:upstreams]
            options[:upstreams].each do |u|
              next if u.match(/\A\d{1,3}\.\d{1,3}\.\d{1,3}.\d{1,3}:\d+\z/)
              puts "ERROR: #{u} is not valid upstream definition, "\
                   'use IP:PORT schema'
              exit(1)
            end
          else
            puts 'ERROR: Upstream locations are not set'
            exit(1)
          end
        end

        Redirus.config_path = options[:config_path]
      end

      def add?
        options[:action] == :add
      end

      def add
        puts "Adding new redirection #{options[:name]} with following "\
             "upstreams #{options[:upstreams]}"

        Sidekiq::Client.push(
          'queue' => options[:queue],
          'class' => Redirus::Worker::AddProxy,
          'args' => [options[:name],
                     options[:upstreams],
                     options[:type], options[:location_properties],
                     options[:options]])
      end

      def rm
        puts "Removing redirection #{options[:name]}"

        Sidekiq::Client.push(
          'queue' => options[:queue],
          'class' => Redirus::Worker::RmProxy,
          'args' => [options[:name], options[:type]])
      end
    end
  end
end
