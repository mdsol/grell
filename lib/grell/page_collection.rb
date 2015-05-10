module Grell
  # Keeps a record of all the pages crawled.
  # When a new url is found it is added to this collection, which makes sure it is unique.
  # This page is part of the discovered pages. Eventually that page will be navigated to, then
  # the page will be part of the visited pages.
  class PageCollection
    attr_reader :collection

    def initialize
      @collection = []
    end

    def create_page(url, parent_id)
      page_id = next_id
      page = Page.new(url, page_id, parent_id)
      add(page)
      page
    end

    def visited_pages
      @collection.select {|page| page.visited?}
    end

    def discovered_pages
      @collection - visited_pages
    end

    def next_page
      discovered_pages.sort_by{|page| page.parent_id}.first
    end

    private

    def next_id
      @collection.size
    end

    def add(page)
      # Although finding unique pages based on URL will add pages with different query parameters,
      # in some cases we do link to different pages depending on the query parameters like when using proxies
      new_url = @collection.none? do |collection_page|
        collection_page.url.downcase == page.url.downcase
      end
      if new_url
        @collection.push page
      end
    end

  end
end
