require 'rubygems'
require 'bundler/setup'

require 'redirus/worker/proxy'
require 'redirus/worker/nginx_config_generator'

Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
    # Disable the old-style object.should syntax.
    config.expect_with :rspec do |c|
      c.syntax = :expect
    end
end