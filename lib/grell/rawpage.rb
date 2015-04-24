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
      # Some elements may not be "a" elements but still provide a link. This usually is done for Javascript
      # to convert other elements which are not links to be able to be clicked naturally.
      all('[href]', visible: false).to_a + all('[data-href]', visible: false).to_a
    end


    def host
      page.current_host
    end

    def has_selector?(selector)
      page.has_selector?(selector)
    end
  end
end
