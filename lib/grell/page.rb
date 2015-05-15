require 'forwardable'

module Grell
 # This class contains the logic related to work with each page we crawl. It is also the interface we use
 # To access the information of each page.
 # This information comes from result private classes below.
  class Page
    extend Forwardable

    WAIT_TIME = 10
    WAIT_INTERVAL = 0.5

    attr_reader :url, :timestamp, :id, :parent_id, :rawpage

    #Most of the interesting information accessed through this class is accessed by the methods below
    def_delegators :@result_page, :headers, :body, :status, :links, :has_selector?, :host, :visited?

    def initialize( url, id, parent_id)
      @rawpage = RawPage.new
      @url = url
      @id = id
      @parent_id = parent_id
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
      @times_visited += 1
    rescue Capybara::Poltergeist::JavascriptError => e
      unavailable_page(404, e)
    rescue Capybara::Poltergeist::BrowserError => e #This may happen internally on Poltergeist, they claim is a bug.
      unavailable_page(404, e)
    rescue URI::InvalidURIError => e #No cool URL means we report error
      unavailable_page(404, e)
    rescue Capybara::Poltergeist::TimeoutError => e #Poltergeist has its own timeout which is similar to Chromes.
      unavailable_page(404, e)
    rescue Capybara::Poltergeist::StatusFailError => e
      unavailable_page(404, e)
    rescue Timeout::Error => e #This error inherits from Interruption, do not inherit from StandardError
      unavailable_page(404, e)
    end

    def retries
      [@times_visited -1, 0].max
    end

    private
    def unavailable_page(status, exception)
      Grell.logger.warn "The page with the URL #{@url} was not available. Exception #{exception}"
      @result_page = ErroredPage.new(status, exception)
      @timestamp = Time.now
    end

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
        {grellStatus: 'NotVisited' }
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
      end

      def status
        @rawpage.status
      end

      def body
        @rawpage.body
      end

      def headers
        @rawpage.headers
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
        # <link> can only be used in the <head> as of: https://developer.mozilla.org/en/docs/Web/HTML/Element/link
        anchors_in_body = @rawpage.all_anchors.reject{|anchor| anchor.tag_name == 'link' }

        unique_links = anchors_in_body.map do |anchor|
         anchor['href'] || anchor['data-href']
        end.compact

        unique_links.map{|link| link_to_url(link)}.uniq.compact

      rescue Capybara::Poltergeist::ObsoleteNode
        Grell.logger.warn "We found an obsolete node in #{@url}. Ignoring all links"
        # Sometimes Javascript and timing may screw this, we lose these links.
        # TODO: Can we do something more intelligent here?
        []
      end

      # We only accept links in this same host that start with a path
      # nil from this
      def link_to_url(link)
        uri = URI.parse(link)
        if uri.absolute?
          if uri.host != URI.parse(host).host
            Grell.logger.debug "GRELL does not follow links to external hosts: #{link}"
            nil
          else
            link # Absolute link to our own host
          end
        else
          if uri.path.nil?
            Grell.logger.debug "GRELL does not follow links without a path: #{uri}"
            nil
          end
          if uri.path.start_with?('/')
            host + link  #convert to full URL
          else #links like href="google.com" the browser would go to http://google.com like "http://#{link}"
            Grell.logger.debug "GRELL Bad formatted link: #{link}, assuming external"
            nil
          end
        end

      rescue URI::InvalidURIError #We will have invalid links propagating till we navigate to them
        link
      end
    end



  end

end
