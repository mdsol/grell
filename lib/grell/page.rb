module Grell

  #This class contains the logic related to work with each page we crawl
  class Page

    attr_reader :url, :timestamp, :links, :status, :headers, :body, :id, :parent_id
    attr_accessor :visited

    def initialize( url, id, parent_id)
      @rawpage = RawPage.new
      @url = url
      @links = []
      @id = id
      @parent_id = parent_id
      @visited = false
      @status = nil
      @body = nil
      @timestamp = nil
      @headers = nil
    end

    def navigate
      if(@rawpage.navigate(@url))
        @visited = true
        @timestamp = Time.now
        @links = all_links
        @status = response.status
        @headers = format_headers
        @body = @rawpage.body
      else
        unavailable_page(nil)
      end
    rescue URI::InvalidURIError
      unavailable_page(404)
    rescue Capybara::Poltergeist::TimeoutError
      unavailable_page(404)
    end

    def host
      @rawpage.host
    end

    def visited?
      @visited
    end

    #TODO: use Capybara for this instead.
    def response
      @response ||= begin
        response = @rawpage.response
        count = 50
        while (count > 0 && response.nil?)
          sleep(0.2)
          response = @rawpage.response
        end
        response
      end
    end

    def path
      URI.parse(@url).path
    rescue URI::InvalidURIError #Invalid URLs will be added and cought when we try to navigate to them
      @url
    end

    private

    def unavailable_page(status)
      @visited = true
      @timestamp = Time.now
      @links =  []
      @status = status
      @headers = []
      @body = ''
    end

    def all_links
      unique_links = @rawpage.all_links.map { |a| a[:href] }.uniq.compact
      unique_links.map { |link| link_to_url(link) }.compact
    rescue Capybara::Poltergeist::ObsoleteNode
      Log.warning "We found an obsolete node in #{@url}. Ignoring all links"
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

    def format_headers
      response.headers.inject({}) do |result_hash, one_header_hash|
        current_name = one_header_hash['name']
        current_value =  one_header_hash['value']
        result_hash[current_name] = current_value
        result_hash
      end
    end


  end

end
