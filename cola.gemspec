# -*- encoding: utf-8 -*-
# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "cola/version"

Gem::Specification.new do |spec|
  spec.name        = 'rb-cola'
  spec.version     = Cola::VERSION
  spec.authors     = ['Khash Sajadi']
  spec.email       = ['khash@cloud66.com']
  spec.homepage    = 'https://github.com/cloud66-oss/rb-cola'
  spec.summary     = 'A distributed queue based on Redis'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir = "bin"
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'redis', '>= 3.3.5', '< 5'

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rspec", "~> 3.8"
  spec.add_development_dependency "byebug", "~> 11.0"
end
