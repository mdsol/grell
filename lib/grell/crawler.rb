module Grell
  # This is the class that starts and controls the crawling
  class Crawler
    attr_reader :collection, :manager

    # Creates a crawler
    # evaluate_in_each_page: javascript block to evaluate in each page we crawl
    # add_match_block: block to evaluate to consider if a page is part of the collection
    # manager_options: options passed to the manager class
    # allowlist: Sets an allowlist filter, allows a regexp, string or array of either to be matched.
    # denylist: Sets a denylist filter, allows a regexp, string or array of either to be matched.
    def initialize(evaluate_in_each_page: nil, add_match_block: nil, allowlist: /.*/, denylist: /a^/, **manager_options)
      @collection = nil
      @manager = CrawlerManager.new(manager_options)
      @evaluate_in_each_page = evaluate_in_each_page
      @add_match_block = add_match_block
      @allowlist_regexp = Regexp.union(allowlist)
      @denylist_regexp = Regexp.union(denylist)
    end

    # Main method, it starts crawling on the given URL and calls a block for each of the pages found.
    def start_crawling(url, &block)
      Grell.logger.info "GRELL Started crawling"
      @collection = PageCollection.new(@add_match_block)
      @collection.create_page(url, nil)

      while !@collection.discovered_pages.empty?
        crawl(@collection.next_page, block)
        @manager.check_periodic_restart(@collection)
      end

      Grell.logger.info "GRELL finished crawling"
    end

    def crawl(site, block)
      Grell.logger.info "Visiting #{site.url}, visited_links: #{@collection.visited_pages.size}, discovered #{@collection.discovered_pages.size}"
      crawl_site(site)

      if block # The user of this block can send us a :retry to retry accessing the page
        while crawl_block(block, site) == :retry
          Grell.logger.info "Retrying our visit to #{site.url}"
          crawl_site(site)
        end
      end

      site.links.each do |url|
        @collection.create_page(url, site.id)
      end
    end

    private

    def crawl_site(site)
      site.navigate
      site.rawpage.page.evaluate_script(@evaluate_in_each_page) if @evaluate_in_each_page
      filter!(site.links)
      add_redirect_url(site)
    end

    # Treat any exceptions from the block as an unavailable page
    def crawl_block(block, site)
      block.call(site)
    rescue Capybara::Poltergeist::BrowserError, Capybara::Poltergeist::DeadClient,
           Capybara::Poltergeist::JavascriptError, Capybara::Poltergeist::StatusFailError,
           Capybara::Poltergeist::TimeoutError, Errno::ECONNRESET, URI::InvalidURIError => e
      site.unavailable_page(404, e)
    end

    def filter!(links)
      links.select! { |link| link =~ @allowlist_regexp } if @allowlist_regexp
      links.delete_if { |link| link =~ @denylist_regexp } if @denylist_regexp
    end

    # Store the resulting redirected URL along with the original URL
    def add_redirect_url(site)
      if site.url != site.current_url
        @collection.create_page(site.current_url, site.id)
      end
    end

  end

end
