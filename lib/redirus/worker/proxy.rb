require 'sidekiq'

module Redirus
  module Worker
    class Proxy
      include Sidekiq::Worker

      def perform(proxies=[], properties=[])
        puts "Generating proxies configuration #{proxies} #{properties}"
      end
    end
  end
end