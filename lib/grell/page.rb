module Grell

  #This class contains the logic related to work with each page we crawl
  class Page

    WAIT_TIME = 10
    WAIT_INTERVAL = 0.5

    attr_reader :url, :timestamp, :links, :id, :parent_id, :rawpage
    attr_accessor :visited

    def initialize( url, id, parent_id)
      @rawpage = RawPage.new
      @url = url
      @links = []
      @id = id
      @parent_id = parent_id
      @visited = false
      @timestamp = nil
    end

    def navigate
      # We wait a maximum of WAIT_TIME seconds to get an HTML page. We try or best to workaround inconsistencies on poltergeist
      Reader.wait_for(->{@rawpage.navigate(url)}, WAIT_TIME, WAIT_INTERVAL ) do
        @rawpage.status && !@rawpage.headers.empty? &&
          @rawpage.headers["Content-Type"] && @rawpage.headers["Content-Type"].include?('text/html').equal?(true)
      end
      @visited = true
      @timestamp = Time.now
      @links = all_links
    rescue Capybara::Poltergeist::JavascriptError
      unavailable_page(404)
    rescue Capybara::Poltergeist::BrowserError #This may happen internally on Poltergeist, they claim is a bug.
      unavailable_page(404)
    rescue URI::InvalidURIError #No cool URL means we report error
      unavailable_page(404)
    rescue Capybara::Poltergeist::TimeoutError #Poltergeist has its own timeout which is similar to Chromes.
      unavailable_page(404)
    end

    def headers
      return {grell_status: 'NotVisited' } unless @visited
      @rawpage.headers
    rescue Capybara::Poltergeist::BrowserError #This may happen internally on Poltergeist, they claim is a bug.
      { grell_status: 'BrowserError'}
    end

    def body
      return '' unless @visited
      @rawpage.body
    end

    def status
      return nil unless @visited
      @rawpage.status
    end

    def has_selector?(selector)
      return false unless @visited
      @rawpage.has_selector?(selector)
    end

    def host
      @rawpage.host
    end

    def visited?
      @visited
    end

    def path
      URI.parse(@url).path
    rescue URI::InvalidURIError #Invalid URLs will be added and cought when we try to navigate to them
      @url
    end

    private

    def unavailable_page(status)
      Log.warn "The page with the URL #{@url} was not available"
      @visited = true
      @timestamp = Time.now
      @links =  []
      @status = status
      @headers = {}
      @body = ''
    end

    def all_links
      # <link> can only be used in the <head> as of: https://developer.mozilla.org/en/docs/Web/HTML/Element/link
      anchors_in_body = @rawpage.all_anchors.reject{|anchor| anchor.tag_name == 'link' }

      unique_links = anchors_in_body.map do |anchor|
       anchor['href'] || anchor['data-href']
      end.compact

      unique_links.map { |link| link_to_url(link) }.uniq.compact

    rescue Capybara::Poltergeist::ObsoleteNode
      Log.warn "We found an obsolete node in #{@url}. Ignoring all links"
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
          Log.info "GRELL does not follow links to external hosts: #{link}"
          nil
        else
          link # Absolute link to our own host
        end
      else
        if uri.path.nil?
          Log.info "GRELL does not follow links without a path: #{uri}"
          nil
        end
        if uri.path.start_with?('/')
          host + link  #convert to full URL
        else #links like href="google.com" the browser would go to http://google.com like "http://#{link}"
          Log.info "GRELL Bad formatted link: #{link}, assuming external"
          nil
        end
      end

    rescue URI::InvalidURIError #We will have invalid links propagating till we navigate to them
      link
    end

  end

end
