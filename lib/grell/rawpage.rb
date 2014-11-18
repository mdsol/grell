module Grell
  # This class depends heavily on Capybara but contains no logic.
  class RawPage
    include Capybara::DSL

    def navigate(url)
      visit(url)
    end

    def headers
      page.response_headers
    end

    def status
      page.status_code
    end

    def body
      page.body
    end

    def all_anchors
      all('a', visible: false)
    end

    def host
      page.current_host
    end

    def has_selector?(selector)
      page.has_selector?(selector)
    end
  end
end
