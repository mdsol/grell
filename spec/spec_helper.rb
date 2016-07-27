require 'grell'
require 'byebug'
require 'timecop'
require 'webmock/rspec'
require 'billy/capybara/rspec'
require 'rack'
require 'rack/server'

# This will trick Puffing-billy into using this logger instead of its own
# Puffing billy is very noisy and we do not want to see that in our output
class Rails
  def self.logger
    Logger.new(nil)
  end
end

WebMock.disable_net_connect!


# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|

  # We do not need to wait for pages to return all the data
  config.before do
    stub_const("Grell::Page::WAIT_TIME", 0)
  end

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object.
    mocks.verify_partial_doubles = true
  end

  # Limits the available syntax to the non-monkey patched syntax that is recommended.
  config.disable_monkey_patching!

  # This setting enables warnings. It's recommended, but in some cases may
  # be too noisy due to issues in dependencies.
  # TODO: Billy puffy has lots of warnings, test this with new versions
  # config.warnings = true

  # Many RSpec users commonly either run the entire suite or an individual
  # file, and it's useful to allow more verbose output when running an
  # individual spec file.
  if config.files_to_run.one?
    # Use the documentation formatter for detailed output,
    # unless a formatter has already been configured
    # (e.g. via a command-line flag).
    config.default_formatter = 'doc'
  end

  config.order = :random
  Kernel.srand config.seed

  Capybara.javascript_driver = :poltergeist_billy
  Capybara.default_driver = :poltergeist_billy

#  config.profile_examples = 10
end


