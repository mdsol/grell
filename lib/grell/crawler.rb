
module Grell

  # This is the class that starts and controls the crawling
  class Crawler
    attr_reader :collection

    # Creates a crawler
    # options allows :logger to point to an object with the same interface than Logger in the standard library
    def initialize(options = {})
      @driver = CapybaraDriver.setup(options)

      if options[:logger]
        Grell.logger = options[:logger]
      else
        Grell.logger = Logger.new(STDOUT)
      end

      @collection = PageCollection.new
    end

    # Restarts the PhantomJS process without modifying the state of visited and discovered pages.
    def restart
      Grell.logger.info "GRELL is restarting"
      @driver.restart
      Grell.logger.info "GRELL has restarted"
    end

    # Setups a whitelist filter, allows a regexp, string or array of either to be matched.
    def whitelist(list)
      @whitelist_regexp = Regexp.union(list)
    end

    # Setups a blacklist filter, allows a regexp, string or array of either to be matched.
    def blacklist(list)
      @blacklist_regexp = Regexp.union(list)
    end

    # Main method, it starts crawling on the given URL and calls a block for each of the pages found.
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
      add_redirect_url(site)

      if block #The user of this block can send us a :retry to retry accessing the page
        begin
          while block.call(site) == :retry
            Grell.logger.info "Retrying our visit to #{site.url}"
            site.navigate
            filter!(site.links)
            add_redirect_url(site)
          end
        rescue => e
          site.unavailable_page(404, e)
          return
        end
      end

      site.links.each do |url|
        @collection.create_page(url, site.id)
      end
    end

    private

    def filter!(links)
      links.select!{ |link| link =~ @whitelist_regexp } if @whitelist_regexp
      links.delete_if{ |link| link =~ @blacklist_regexp } if @blacklist_regexp
    end

    # Keep track of the
    def add_redirect_url(site)
      if site.url != site.current_url
        @collection.create_page(site.current_url, site.id)
      end
    end

  end

end
