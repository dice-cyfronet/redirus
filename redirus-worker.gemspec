# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'redirus/worker/version'

Gem::Specification.new do |spec|
  spec.name          = 'redirus-worker'
  spec.version       = Redirus::Worker::VERSION
  spec.authors       = ['Marek Kasztelnik']
  spec.email         = ['mkasztelnik@gmail.com']
  spec.description   = %q{Redirus worker}
  spec.summary       = %q{Worker is responsible for managing http/https/tcp/upd redirections}
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'sidekiq'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'guard-rspec', '~>3.0.2'
  spec.add_development_dependency 'libnotify'
  spec.add_development_dependency 'shoulda-matchers'

  if ENV['TRAVIS']
    spec.add_development_dependency 'coveralls'
  end
end
