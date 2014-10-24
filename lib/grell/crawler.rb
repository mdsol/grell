require 'logger'

module Grell
  Log = Logger.new(STDOUT)

  # This is the class that starts and controls the crawling
  class Crawler
    include Capybara::DSL
    attr_reader :collection

    def initialize(options = {})
      setup_capybara
      if options[:debug]
        Log.level = Logger::INFO
      else
        Log.level = Logger::WARN
      end
      @options = options
    end

    def start_crawling(url, &block)
      new_collection(url)
      @collection.create_page(url, nil)
      while !@collection.discovered_pages.empty?
        Log.debug "Discovered: #{@collection.discovered_pages.size}"
        crawl(@collection.next_page, block)
      end
      Log.info "we are done"
    end

    def crawl(site, block)
      Log.info "  "
      Log.info "Visiting #{site.url}, visited_links: #{@collection.visited_pages.size}, discovered #{@collection.discovered_pages.size}"
      site.navigate

      block.call(site)

      site.links.each do |url|
      #  url = site.host + link
        @collection.create_page(url, site.id)
      end
    end

    private
    require 'byebug'
    def new_collection(url)
      uri = URI.parse(url)
      host = "#{uri.scheme}://#{uri.host}"
      @collection = PageCollection.new(host)
    rescue URI::InvalidURIError => e
      raise "URL to start crawling was not valid #{e.message}"
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
