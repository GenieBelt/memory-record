# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'memory_record/version'

Gem::Specification.new do |spec|
  spec.name          = 'memory_record'
  spec.version       = MemoryRecord::VERSION
  spec.authors       = ['Kacper Kawecki']
  spec.email         = ['kacper@geniebelt.com']

  spec.summary       = %q{Simple indexed in-memory storage for objects}
  spec.description   = %q{Allows storing objects with index based on their class and primary/foreign keys}
  spec.homepage      = 'https://github.com/GenieBelt/memory-record'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.11'
  spec.add_development_dependency 'rake', '~> 10.0'
end
