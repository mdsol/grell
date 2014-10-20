module Grell

  class Crawler
    include Capybara::DSL
    attr_reader :collection

    def initialize(options = {})
      setup_capybara
      @collection = PageCollection.new
      @options = options
    end

    def start_crawling(url, &block)
       site = @collection.create(url, nil)
      while !@collection.discovered_pages.empty?
        crawl(@collection.next_page, block)
      end
      log "we are done"
    end

    def crawl(site, block)
      log "  "
      log "Visiting #{site.url}, visited_links: #{@collection.visited_pages.size}, discovered #{@collection.discovered_pages.size}"
      site.navigate

      block.call(site)

      site.links.each do |link|
        url = site.host + link
        @collection.create(url, site.id)
      end
    end

    private

    def log(message)
      if @options[:debug]
        puts message
      end
    end

    def setup_capybara
      Capybara.register_driver :poltergeist_crawler do |app|
        Capybara::Poltergeist::Driver.new(app, {
          js_errors: false,
          inspector: false,
          phantomjs_logger: open('/dev/null'),
          phantomjs_options: ['--debug=no', '--load-images=no', '--ignore-ssl-errors=yes', '--ssl-protocol=TLSv1']
         })
      end

      Capybara.default_wait_time = 3
      Capybara.run_server = false
      Capybara.default_driver = :poltergeist_crawler
      page.driver.headers = {
        "DNT" => 1,
        "User-Agent" => "Mozilla/5.0 (Grell Crawler)"
      }
    end
  end

end
