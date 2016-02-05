
module Grell

  # This is the class that starts and controls the crawling
  class Crawler
    attr_reader :collection

    # Creates a crawler
    # options allows :logger to point to an object with the same interface than Logger in the standard library
    def initialize(options = {})
      if options[:logger]
        Grell.logger = options[:logger]
      else
        Grell.logger = Logger.new(STDOUT)
      end

      @driver = CapybaraDriver.setup(options)
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
    def start_crawling(url, options = {}, &block)
      Grell.logger.info "GRELL Started crawling"
      @collection = PageCollection.new(options[:add_match_block] || default_add_match)
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

      if block # The user of this block can send us a :retry to retry accessing the page
        begin
          while block.call(site) == :retry
            Grell.logger.info "Retrying our visit to #{site.url}"
            site.navigate
            filter!(site.links)
            add_redirect_url(site)
          end
        rescue Capybara::Poltergeist::BrowserError, Capybara::Poltergeist::DeadClient,
               Capybara::Poltergeist::JavascriptError, Capybara::Poltergeist::StatusFailError,
               Capybara::Poltergeist::TimeoutError, Errno::ECONNRESET, URI::InvalidURIError => e
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
      links.select! { |link| link =~ @whitelist_regexp } if @whitelist_regexp
      links.delete_if { |link| link =~ @blacklist_regexp } if @blacklist_regexp
    end

    # If options[:add_match_block] is not provided, url matching to determine if a
    # new page should be added the page collection will default to this proc
    def default_add_match
      Proc.new do |collection_page, page|
        collection_page.url.downcase == page.url.downcase
      end
    end

    # Store the resulting redirected URL along with the original URL
    def add_redirect_url(site)
      if site.url != site.current_url
        @collection.create_page(site.current_url, site.id)
      end
    end

  end

end
