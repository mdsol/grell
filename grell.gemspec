# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'grell/version'

Gem::Specification.new do |spec|
  spec.name          = "grell"
  spec.version       = Grell::VERSION
  spec.platform      = Gem::Platform::RUBY
  spec.authors       = ["Jordi Polo Carres"]
  spec.email         = ["jcarres@mdsol.com"]
  spec.summary       = %q{Ruby web crawler}
  spec.description   = %q{Ruby web crawler using PhantomJS}
  spec.homepage      = "https://github.com/mdsol/grell"
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 1.9.3'

  spec.add_dependency 'capybara', '~> 2.7'
  spec.add_dependency 'poltergeist', '~> 1.10'

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "byebug", "~> 4.0"
  spec.add_development_dependency "kender", '~> 0.2'
  spec.add_development_dependency "rake", '~> 10.0'
  spec.add_development_dependency "webmock", '~> 1.18'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'puffing-billy', '~> 0.5'
  spec.add_development_dependency 'timecop', '~> 0.8'
end
