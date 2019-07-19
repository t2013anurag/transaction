# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'transaction/version'

Gem::Specification.new do |spec|
  spec.name          = 'transaction'
  spec.version       = Transaction::VERSION
  spec.authors       = ['Anurag Tiwari']
  spec.email         = ['tiwari.anurag126@gmail.com']

  spec.summary       = 'Record status of long running transactions.'
  spec.description   = 'Record status of long running transactions.'
  spec.homepage      = 'https://github.com/t2013anurag/transaction'
  spec.license       = 'MIT'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been
  # added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0")
                     .reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.4.0'
  spec.add_dependency 'redis', '>= 4.0.2'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 12.3'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'simplecov'
end
