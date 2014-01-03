require 'rubygems'
require 'bundler/setup'

require 'redirus/config'
require 'redirus/worker/proxy'
require 'redirus/worker/add_proxy'
require 'redirus/worker/rm_proxy'

SPEC_DIR = File.dirname(__FILE__)
Dir[SPEC_DIR + "/support/**/*.rb"].each {|f| require f}

if ENV['TRAVIS']
  require 'coveralls'
  Coveralls.wear!
end

RSpec.configure do |config|
    # Disable the old-style object.should syntax.
    config.expect_with :rspec do |c|
      c.syntax = :expect
    end

    config.alias_example_to :expect_it
end

RSpec::Core::MemoizedHelpers.module_eval do
  alias to should
  alias to_not should_not
end