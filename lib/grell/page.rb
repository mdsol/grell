require 'forwardable'

module Grell
 # This class contains the logic related to work with each page we crawl. It is also the interface we use
 # To access the information of each page.
 # This information comes from result private classes below.
  class Page
    extend Forwardable

    WAIT_TIME = 10
    WAIT_INTERVAL = 0.5

    attr_reader :url, :timestamp, :id, :parent_id, :parent_pages, :rawpage

    #Most of the interesting information accessed through this class is accessed by the methods below
    def_delegators :@result_page, :headers, :body, :status, :links, :has_selector?, :host, :visited?

    def initialize( url, id, parent_pages)
      @rawpage = RawPage.new
      @url = url
      @id = id
      @parent_pages = parent_pages
      @parent_id = @parent_pages.last.id if @parent_pages
      @timestamp = nil
      @times_visited = 0
      @result_page = UnvisitedPage.new
    end

    def navigate
      # We wait a maximum of WAIT_TIME seconds to get an HTML page. We try or best to workaround inconsistencies on poltergeist
      Reader.wait_for(->{@rawpage.navigate(url)}, WAIT_TIME, WAIT_INTERVAL ) do
        @rawpage.status && !@rawpage.headers.empty? &&
          @rawpage.headers["Content-Type"] && @rawpage.headers["Content-Type"].include?('text/html').equal?(true)
      end
      @result_page = VisitedPage.new(@rawpage)
      @timestamp = Time.now
    rescue Capybara::Poltergeist::BrowserError, Capybara::Poltergeist::DeadClient,
           Capybara::Poltergeist::JavascriptError, Capybara::Poltergeist::StatusFailError,
           Capybara::Poltergeist::TimeoutError, Errno::ECONNRESET, URI::InvalidURIError => e
      unavailable_page(404, e)
    ensure
      @times_visited += 1
    end

    # Number of times we have retried the current page
    def retries
      [@times_visited - 1, 0].max
    end

    # The current URL, this may be different from the URL we asked for if there was some redirect
    def current_url
      @rawpage.current_url
    end

    # True if we followed a redirect to get the current contents
    def followed_redirects?
      current_url != @url
    end

    # True if there page responded with an error
    def error?
      !!(status.to_s =~ /[4|5]\d\d/)
    end

    # Extracts the path (e.g. /actions/test_action) from the URL
    def path
      URI.parse(@url).path
    rescue URI::InvalidURIError # Invalid URLs will be added and caught when we try to navigate to them
      @url
    end

    def unavailable_page(status, exception)
      Grell.logger.warn "The page with the URL #{@url} was not available. Exception #{exception}"
      @result_page = ErroredPage.new(status, exception)
      @timestamp = Time.now
    end

    private

    # Private class.
    # This is a result page when it has not been visited yet. Essentially empty of information
    #
    class UnvisitedPage
      def status
        nil
      end

      def body
        ''
      end

      def headers
        { grellStatus: 'NotVisited' }
      end

      def links
        []
      end

      def host
        ''
      end

      def visited?
        false
      end

      def has_selector?(selector)
        false
      end

    end

    # Private class.
    # This is a result page when some error happened. It provides some information about the error.
    #
    class ErroredPage
      def initialize(error_code, exception)
        @error_code = error_code
        @exception = exception
      end

      def status
        @error_code
      end

      def body
        ''
      end

      def headers
        message = begin
          @exception.message
        rescue StandardError
          "Error message can not be accessed" #Poltergeist may try to access a nil object when accessing message
        end

        {
          grellStatus: 'Error',
          errorClass: @exception.class.to_s,
          errorMessage: message
        }
      end

      def links
        []
      end

      def host
        ''
      end

      def visited?
        true
      end

      def has_selector?(selector)
        false
      end

    end


    # Private class.
    # This is a result page when we successfully got some information back after visiting the page.
    # It delegates most of the information to the @rawpage capybara page. But any transformation or logic is here
    #
    class VisitedPage
      def initialize(rawpage)
        @rawpage = rawpage
        @headers = @rawpage.headers
      end

      def status
        @rawpage.status
      end

      def body
        @rawpage.body
      end

      def headers
        @headers
      rescue Capybara::Poltergeist::BrowserError => e #This may happen internally on Poltergeist, they claim is a bug.
        {
          grellStatus: 'Error',
          errorClass: e.class.to_s,
          errorMessage: e.message
        }
      end

      def links
        @links ||= all_links
      end

      def host
        @rawpage.host
      end

      def visited?
        true
      end

      def has_selector?(selector)
        @rawpage.has_selector?(selector)
      end

      private
      def all_links
        links =  @rawpage.all_anchors.map { |anchor| Link.new(anchor) }
        body_enabled_links = links.reject { |link| link.inside_header? || link.disabled? || link.js_href? }
        body_enabled_links.map { |link| link.to_url(host) }.uniq.compact

      rescue Capybara::Poltergeist::ObsoleteNode
        Grell.logger.warn "We found an obsolete node in #{@url}. Ignoring all links"
        # Sometimes Javascript and timing may screw this, we lose these links.
        # TODO: Can we do something more intelligent here?
        []
      end

      # Private class to group all the methods related to links.
      class Link
        def initialize(anchor)
          @anchor = anchor
        end

        # <link> can only be used in the <head> as of: https://developer.mozilla.org/en/docs/Web/HTML/Element/link
        def inside_header?
          @anchor.tag_name == 'link'
        end

        # Is the link disabled by either Javascript or CSS?
        def disabled?
          @anchor.disabled? || !!@anchor.native.attributes['disabled']
        end

        # Does the href use javascript?
        def js_href?
          href.start_with?('javascript:')
        end

        # Some links may use data-href + javascript to do interesting things
        def href
          @anchor['href'] || @anchor['data-href']
        end

        # We only accept links in this same host that start with a path
        def to_url(host)
          uri = URI.parse(href)
          if uri.absolute?
            if uri.host != URI.parse(host).host
              Grell.logger.debug "GRELL does not follow links to external hosts: #{href}"
              nil
            else
              href # Absolute link to our own host
            end
          else
            if uri.path.nil?
              Grell.logger.debug "GRELL does not follow links without a path: #{uri}"
              nil
            end
            if uri.path.start_with?('/')
              host + href  # convert to full URL
            else # links like href="google.com" the browser would go to http://google.com like "http://#{link}"
              Grell.logger.debug "GRELL Bad formatted link: #{href}, assuming external"
              nil
            end
          end
        rescue URI::InvalidURIError # Invalid links propagating till we navigate to them
          href
        end
      end

    end
  end
end
