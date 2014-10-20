# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'grell/version'

Gem::Specification.new do |spec|
  spec.name          = "grell"
  spec.version       = Grell::VERSION
  spec.authors       = ["Jordi Polo Carres"]
  spec.email         = ["jcarres@mdsol.com"]
  spec.summary       = %q{Ruby web crawler}
  spec.description   = %q{Ruby web crawler using PhantomJS}
  spec.homepage      = "https://github.com/mdsol/grell"
  spec.license       = "MIT"

  spec.files         = Dir['lib/**/*'] #`git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'capybara', '~> 2.2'
  spec.add_dependency 'poltergeist', '~> 1.5'

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "byebug", "~> 3.5"
  spec.add_development_dependency "webmock", '~> 1.18'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
