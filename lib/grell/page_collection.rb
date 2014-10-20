module Grell
  class PageCollection
    attr_reader :collection

    def initialize
      @collection = []
    end

    def create(url, parent_id)
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

    def next_id
      @collection.size
    end

    def add(page)
      if @collection.none?{ |collection_page| collection_page.url == page.url}
        @collection.push page
      end
    end

    def next_page
      discovered_pages.sort_by{|page| page.parent_id}.first
    end

    def more_to_crawl?
      # The first time there is nothing in the arrays but still something to crawl
      # then whenever visited_pages have anything we need to only look at discovered_pages
      visited_pages.empty? && discovered_pages.empty? || (!discovered_pages.empty?)
    end

  end
end
