require 'erb'

module Redirus
  module Worker
    class AddProxy < Proxy

      def perform_action(name, workers, type, location_props = nil, opt = {})
        Action.new(name, workers, type, location_props, opt).execute
      end

      private

      class Action
        include Redirus::Utils

        def initialize(name, workers, type, location_props, options = {})
          @name = name
          @workers = workers
          @type = type
          @location_properties = location_properties(location_props) || []
          @options = options
        end

        attr_reader :name, :workers, :type

        def execute
          File.open(config_file_path(name, type), 'w') do |file|
            erb = ERB.new(template, nil, '-')
            file.write erb.result(binding)
          end
        end

        private

        def location_properties(props)
          props.inject([]) do |tab, prop|
            tab << prop if allowed? prop
            tab
          end if props
        end

        def allowed?(prop)
          config.
            allowed_properties.
            any? { |prop_regexp| /#{prop_regexp}/.match(prop) }
        end

        def template
          File.read(template_path)
        end

        def template_path
          https? ? config.https_template : config.http_template
        end

        def https?
          type.to_s == 'https'
        end
      end
    end
  end
end
