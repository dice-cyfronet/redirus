# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'redirus/version'

Gem::Specification.new do |spec|
  spec.name          = 'redirus'
  spec.version       = Redirus::VERSION
  spec.authors       = ['Marek Kasztelnik']
  spec.email         = ['mkasztelnik@gmail.com']
  spec.description   = %q{Redirus}
  spec.summary       = %q{Redirus is responsible for managing http/https redirections}
  spec.homepage      = 'https://github.com/dice-cyfronet/redirus'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'sidekiq'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'shoulda-matchers'
  spec.add_development_dependency 'rspec-sidekiq'
  spec.add_development_dependency 'coveralls'
end
