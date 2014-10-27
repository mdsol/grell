module Grell

  # This class depends heavily on Capybara but contains no logic.
  class RawPage
    include Capybara::DSL

    def navigate(url)
      result = visit(url)
      result && result['status'] == "success"
    end

    def response
      page.driver.network_traffic.last.response_parts.first
    end

    def body
      page.body
    end

    def all_links
      all('a', visible: false)
    end

    def host
      page.current_host
    end
  end
end