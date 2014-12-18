require 'optparse'
require 'singleton'
require 'erb'

module Redirus
  module Cli
    class Init
      include Singleton

      attr_reader :options

      def parse(args = ARGV)
        init_options(args)
        validate!
      end

      def run
        generate_templates
        mkdir(@options[:configs_dir])
        mkdir(@options[:log_dir])
      end

      private

      def generate_templates
        Dir[File.join(tmpl_dir, '*')].each { |tmpl| generate(tmpl) }
      end

      def mkdir(dir)
        Dir.mkdir(dir) unless Dir.exist?(dir)
      end

      def tmpl_dir
        @templates ||= File.join(Redirus.root, 'templates')
      end

      def init_options(args)
        opts = parse_options(args)
        @options = defaults.merge(opts)
        @options[:http_template] = target('http.conf.erb')
        @options[:https_template] = target('https.conf.erb')
      end

      def parse_options(args)
        opts = {}

        parser = OptionParser.new do |o|
          o.on('-t', '--target PATH',
               'Target path (default current dir)') do |arg|
            opts[:target] = arg
            opts[:pid] = File.join(arg, 'nginx.pid')
            opts[:configs_dir] = File.join(arg, 'configurations')
            opts[:log_dir] = File.join(arg, 'log')
          end

          o.on('--ip IP', 'Server IP address (default *)') do |arg|
            opts[:ip] = arg
          end

          o.on('--server-name NAME', 'Server name') do |arg|
            opts[:server_name] = arg
          end

          o.on('--ssl-cert PATH', 'Server certificate path') do |arg|
            opts[:ssl_cert] = arg
          end

          o.on('--ssl-cert-key PATH', 'Server certificate key path') do |arg|
            opts[:ssl_cert_key] = arg
          end

          o.on('--nginx-pid PATH',
               'Nginx pid location (default nginx.pid in '\
               'current dir)') do |arg|
            opts[:pid] = arg
          end

          o.on('--configurations DIR',
               'Directory where nginx configs will be generated '\
               '(default "configurations" in current directory)') do |arg|
            opts[:configs_dir] = arg
          end

          o.on('--logs DIR', 'Directory where nginx logs will be placed'\
               '(default "log" dir in current dirrectory)') do |arg|
            opts[:log_dir] = arg
          end

          o.on('--redis URL',
               'Redis location (default "redis://localhost:6379")') do |arg|
            opts[:redis] = arg
          end

          o.on('--queues', Array,
               'List of redirs queues (default ["redirus"]') do |arg|
            opts[:queues] = arg
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

        parser.banner = 'redirus-init [options]'
        parser.parse!(args)

        opts
      end

      def defaults
        {
          target: Dir.pwd,
          ip: '*',
          server_name: 'CHANGE_ME',
          pid: File.join(Dir.pwd, 'nginx.pid'),
          configs_dir: File.join(Dir.pwd, 'configurations'),
          log_dir: File.join(Dir.pwd, 'log'),
          redis: 'redis://localhost:6379',
          queues: ['redirus']
        }
      end

      def validate!
        check_target_dir!
        check_ip!
        check_pid_dir!
      end

      def check_target_dir!
        return if Dir.exist?(options[:target])

        puts "ERROR: Directory #{options[:target]} does not exist"
        exit(1)
      end

      def check_ip!
        return if valid_id?

        puts 'ERROR: Server IP is not valid'
        exit(1)
      end

      def valid_id?
        options[:ip] == '*' ||
          options[:ip].match(/\A\d{1,3}\.\d{1,3}\.\d{1,3}.\d{1,3}:\d+\z/)
      end

      def check_pid_dir!
        return if Dir.exist?(File.dirname(options[:pid]))

        puts 'ERROR: Pid directory does not exist'
        exit(1)
      end

      def generate(tmpl)
        File.open(target(tmpl), 'w') do |file|
          erb = ERB.new(File.read(tmpl), nil, '-')
          file.write(erb.result(binding))
        end
      end

      def target(tmpl)
        File.join(@options[:target], File.basename(tmpl))
      end
    end
  end
end
