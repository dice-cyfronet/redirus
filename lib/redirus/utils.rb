module Redirus
  module Utils
    def full_name(name, type)
      "#{name}_#{type}"
    end

    def config_file_path(name, type)
      File.join(config.configs_path, full_name(name, type))
    end

    def config
      @config ||= Redirus.config
    end
  end
end
