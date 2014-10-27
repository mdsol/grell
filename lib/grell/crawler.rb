
module Grell

  # This is the class that starts and controls the crawling
  class Crawler
    attr_reader :collection

    def initialize(options = {})
      CapybaraDriver.setup(options)

      if options[:debug]
        Log.level = Logger::INFO
      else
        Log.level = Logger::ERROR
      end
      @collection = PageCollection.new
    end


    def start_crawling(url, &block)
      Log.info "GRELL Started crawling"
      @collection = PageCollection.new
      @collection.create_page(url, nil)
      while !@collection.discovered_pages.empty?
        crawl(@collection.next_page, block)
      end
      Log.info "GRELL finished crawling"
    end

    def crawl(site, block)
      Log.info "Visiting #{site.url}, visited_links: #{@collection.visited_pages.size}, discovered #{@collection.discovered_pages.size}"
      site.navigate

      block.call(site) if block

      site.links.each do |url|
        @collection.create_page(url, site.id)
      end
    end

  end

end
