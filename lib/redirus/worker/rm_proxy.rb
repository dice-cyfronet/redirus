module Redirus
  module Worker
    class RmProxy < Proxy

      def perform_action(name, type)
        File.delete(full_name(name, type))
      end
    end
  end
end