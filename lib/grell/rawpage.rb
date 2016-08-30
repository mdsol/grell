module Grell
  # This class depends heavily on Capybara but contains no logic.
  class RawPage
    include Capybara::DSL

    def navigate(url)
      visit(url)
      follow_redirects!
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
      # Only return links which are visible.
      all('[href]', visible: true).to_a + all('[data-href]', visible: true).to_a
    end

    def host
      page.current_host
    end

    def has_selector?(selector)
      page.has_selector?(selector)
    end

    def wait_for_all_ajax_requests(timeout, interval)
      Timeout::timeout(timeout) do
        (timeout / interval).ceil.times do
          jquery_active = page.evaluate_script("typeof jQuery !== 'undefined' && jQuery.active;")
          break if (!jquery_active || jquery_active.zero?)
          sleep(interval)
        end
      end
      true
    end

    private

    def follow_redirects!
      # Phantom is very weird, it will follow a redirect to provide the correct body but will not fill the
      # status and the headers, if we are in that situation, revisit the page with the correct url this time.
      # Note that we will still fail if we have more than 5 redirects on a row
      redirects = 0
      while(page.status_code == nil && redirects < 5)
        visit( CGI.unescape(page.current_url))
        redirects = redirects + 1
      end
    end
  end
end
