module Grell
  class PageCollection
    attr_reader :collection

    def initialize(host)
      @collection = []
      @host = host
    end

    def create_page(url, parent_id)
      page_id = next_id
      page = Page.new(@host, url, page_id, parent_id)
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
      if @collection.none?{ |collection_page| collection_page.url == page.url}
        @collection.push page
      end
    end

  end
end
