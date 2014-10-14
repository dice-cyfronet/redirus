module Redirus
  module Worker
    class AddProxy < Proxy

      def perform_action(name, workers, type, props = nil)
        params = config_propertie(name, workers, type, props)
        File.open(config_file_path(name, type), 'w') do |file|
          param_regexp = '#{\w*}'
          file.write config.config_template
            .gsub(/#{param_regexp}/) { |p| params[p[2..-2]] }
        end
      end

      private

      def config_propertie(name, workers, type, props)
        {
          'name' => name,
          'listen' => https?(type) ? config.https_template : config.http_template,
          'upstream' => upstream_conf(name, workers, type),
          'upstream_name' => full_name(name, type),
          'properties' => location_properties(props)
        }
      end

      def https?(type)
        type.to_s == 'https'
      end

      def upstream_conf(name, workers, type)
        "upstream #{name}_#{type} {\n#{workers_conf(workers)}\}\n"
      end

      def workers_conf(workers)
        workers.collect { |worker| "  server #{worker};\n" }.join
      end

      def location_properties(props)
        props.inject([]) do |tab, prop|
          tab << "#{prop};\n" if allowed? prop
          tab
        end.join('') if props
      end

      def allowed?(prop)
        config.allowed_properties
          .any? { |prop_regexp| /#{prop_regexp}/.match(prop) }
      end
    end
  end
end