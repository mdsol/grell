
module Grell

  #The driver for Capybara. It uses Portelgeist to control PhantomJS
  class CapybaraDriver
    include Capybara::DSL

    USER_AGENT = "Mozilla/5.0 (Grell Crawler)"

    def self.setup(options)
      new.setup_capybara unless options[:external_driver]
    end

    def setup_capybara
      Capybara.register_driver :poltergeist_crawler do |app|
        Capybara::Poltergeist::Driver.new(app, {
          js_errors: false,
          inspector: false,
          phantomjs_logger: open('/dev/null'),
          phantomjs_options: ['--debug=no', '--load-images=no', '--ignore-ssl-errors=yes', '--ssl-protocol=TLSv1']
         })
      end

      Capybara.default_max_wait_time = 3
      Capybara.run_server = false
      Capybara.default_driver = :poltergeist_crawler
      page.driver.headers = {
        "DNT" => 1,
        "User-Agent" => USER_AGENT
      }

      fail "Poltergeist Driver could not be properly initialized" unless Capybara.drivers[:poltergeist_crawler]

      Capybara.drivers[:poltergeist_crawler].yield
    end
  end

end
