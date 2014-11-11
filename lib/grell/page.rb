module Grell

  #This class contains the logic related to work with each page we crawl
  class Page

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
      # We wait a maximum of 10 seconds to get an HTML page. We try or best to workaround inconsistencies on poltergeist
      Reader.wait_for(->{@rawpage.navigate(url)}, 10, 0.5) do
        !headers.empty? &&  headers["Content-Type"] && headers["Content-Type"].include?('text/html').equal?(true)
      end
      @visited = true
      @timestamp = Time.now
      @links = all_links
    rescue URI::InvalidURIError
      unavailable_page(404)
    rescue Capybara::Poltergeist::TimeoutError
      unavailable_page(404)
    end

    def headers
      return {} unless @visited
      @rawpage.headers
    end

    def body
      return '' unless @visited
      @rawpage.body
    end
    def status
      return nil unless @visited
      @rawpage.status
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
      unique_links = @rawpage.all_anchors.map { |a| a[:href] }.uniq.compact
      unique_links.map { |link| link_to_url(link) }.compact
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
      return nil if uri.host && uri.host != host #We do not want other host being defined
      if uri.path.nil?
        Log.info "GRELL does not follow links without a path: #{uri}"
        return nil
      end
      if uri.path.start_with?('/')
        host + link  #convert to full URL
      else #links like href="google.com" the browser would go to http://google.com like "http://#{link}"
        Log.info "GRELL Bad formatted link: #{link}, assuming external"
        nil
      end

    rescue URI::InvalidURIError #We will have invalid links propagating till we navigate to them
      link
    end

  end

end
