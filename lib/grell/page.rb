module Grell

  #This class contains the logic related to work with each page we crawl
  class Page

    attr_reader :url, :timestamp, :links, :status, :headers, :body, :id, :parent_id
    attr_accessor :visited

    def initialize(url, id, parent_id)
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
        @status = @rawpage.response.status
        @headers = format_headers
        @body = @rawpage.body
      else
        @visited = true
        @timestamp = Time.now
        @links =  []
        @status = nil
        @headers = []
        @body = ''
      end
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

    private

    def all_links
      unique_links = @rawpage.all_links.map { |a| a[:href] }.uniq.compact
      only_path_links = unique_links.select do |link|
        uri = URI.parse(link)
        uri.host.nil? && !uri.path.nil? && !uri.path.empty?
      end
      only_path_links
    end

    def format_headers
      @rawpage.response.headers.inject({}) do |result_hash, one_header_hash|
        current_name = one_header_hash['name']
        current_value =  one_header_hash['value']
        result_hash[current_name] = current_value
        result_hash
      end
    end


  end

end
