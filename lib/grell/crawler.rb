
module Grell

  # This is the class that starts and controls the crawling
  class Crawler
    attr_reader :collection

    def initialize(options = {})
      CapybaraDriver.setup(options)

      if options[:logger]
        Grell.logger = options[:logger]
      else
        Grell.logger = Logger.new(STDOUT)
      end

      @collection = PageCollection.new
    end

    def whitelist(list)
      @whitelist_regexp = Regexp.union(list)
    end

    def blacklist(list)
      @blacklist_regexp = Regexp.union(list)
    end


    def start_crawling(url, &block)
      Grell.logger.info "GRELL Started crawling"
      @collection = PageCollection.new
      @collection.create_page(url, nil)
      while !@collection.discovered_pages.empty?
        crawl(@collection.next_page, block)
      end
      Grell.logger.info "GRELL finished crawling"
    end

    def crawl(site, block)
      Grell.logger.info "Visiting #{site.url}, visited_links: #{@collection.visited_pages.size}, discovered #{@collection.discovered_pages.size}"
      site.navigate

      filter!(site.links)

      block.call(site) if block

      site.links.each do |url|
        @collection.create_page(url, site.id)
      end
    end

    private
    def filter!(links)
      links.select!{ |link| link =~ @whitelist_regexp } if @whitelist_regexp
      links.delete_if{ |link| link =~ @blacklist_regexp } if @blacklist_regexp
    end

  end

end
