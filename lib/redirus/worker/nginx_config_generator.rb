module Redirus
  module Worker
    class NginxConfigGenerator

      def initialize(proxies, properties)
        @proxies, @properties = proxies, properties
      end

      attr_reader :proxies, :properties

      def generate
        result = {
          http:  { proxy: StringIO.new, upstream: StringIO.new },
          https: { proxy: StringIO.new, upstream: StringIO.new }
        }

        proxies.each do |proxy|
          result[proxy_type(proxy)][:proxy]    << generate_proxy_conf(proxy)
          result[proxy_type(proxy)][:upstream] << generate_upstream_conf(proxy)
        end

        string_values(result)
      end

      private

      def proxy_type(proxy)
        proxy['type'].to_sym
      end

      def string_values(result)
        result = {
          http:  {
            proxy: result[:http][:proxy].string,
            upstream: result[:http][:upstream].string
          },
          https: {
            proxy: result[:https][:proxy].string,
            upstream: result[:https][:upstream].string
          }
        }
      end

      def generate_proxy_conf(proxy)
        proxy_path = proxy_path(proxy)

        conf = "location \"/#{proxy_path}/\" {\n"\
        "  proxy_pass http:\/\/#{proxy_pass(proxy)}\/;\n"\
        "#{properties_config(proxy)}}\n"
      end

      def proxy_path(proxy)
        proxy_path = proxy['path']
        proxy_path = proxy_path[0..-2] if proxy_path[proxy_path.size - 1] == '/'
        proxy_path = proxy_path[1..(proxy_path.size - 1)] if proxy_path[0] == '/'

        proxy_path
      end

      def proxy_pass(proxy)
        "#{proxy['type']}.#{proxy_path(proxy).gsub('/', '.')}"
      end

      def generate_upstream_conf(proxy)
        proxy_pass = proxy_pass(proxy)
        "upstream #{proxy_pass} {\n#{workers_conf(proxy)}\}\n"
      end

      def workers_conf(proxy)
        proxy['workers'].collect do |worker|
          "  server #{worker};\n"
        end.join
      end

      def properties_config(proxy)
        local_props = proxy['properties'] || []
        [local_props, properties].flatten.collect do |prop|
          "  #{prop.gsub('{{path}}', proxy['path'])};\n"
        end.join
      end
    end
  end
end