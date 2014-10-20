module Grell
  class Page
    include Capybara::DSL

    attr_reader :url, :timestamp, :links, :status, :headers, :body, :id, :parent_id
    attr_accessor :visited

    def initialize(url, id, parent_id)
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
      if(visit(@url)["status"] == "success")
        @visited = true
        @timestamp = Time.now
        @links = all_links
        @status = response.status
        @headers = format_headers
        @body = page.body
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
      page.current_host
    end

    def visited?
      @visited
    end

    #TODO: use Capybara for this instead.
    def response
      @response ||= begin
        response = page.driver.network_traffic.last.response_parts.first
        count = 50
        while (count > 0 && response.nil?)
          sleep(0.2)
          response = page.driver.network_traffic.last.response_parts.first
        end
        response
      end
    end

    private

    def all_links
      unique_links = all('a', visible: false).map { |a| a[:href] }.uniq.compact
      only_path_links = unique_links.select do |link|
        uri = URI.parse(link)
        uri.host.nil? && !uri.path.nil? && !uri.path.empty?
      end
      only_path_links
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
