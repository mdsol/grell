
RSpec.describe Grell::Crawler do
  let(:page_id) { rand(10).floor + 10 }
  let(:parent_page_id) { rand(10).floor }
  let(:page) { Grell::Page.new(url, page_id, parent_page_id) }
  let(:host) { 'http://www.example.com' }
  let(:url) { 'http://www.example.com/test' }
  let(:add_match_block) { nil }
  let(:blacklist) { /a^/ }
  let(:whitelist) { /.*/ }
  let(:crawler) do
    Grell::Crawler.new(
      logger: Logger.new(nil),
      driver_options: { external_driver: true },
      evaluate_in_each_page: script,
      add_match_block: add_match_block,
      blacklist: blacklist,
      whitelist: whitelist)
  end
  let(:script) { nil }
  let(:body) { 'body' }
  let(:custom_add_match) do
    Proc.new do |collection_page, page|
      collection_page.path == page.path
    end
  end

  before do
    proxy.stub(url).and_return(body: body, code: 200)
  end

  describe '#crawl' do
    before do
      crawler.instance_variable_set('@collection', Grell::PageCollection.new(custom_add_match))
    end

    it 'yields the result if a block is given' do
      result = []
      block = Proc.new { |n| result.push(n) }
      crawler.crawl(page, block)
      expect(result.size).to eq(1)
      expect(result.first.url).to eq(url)
      expect(result.first.visited?).to eq(true)
    end

    it 'rescues any specified exceptions raised during the block execution' do
      block = Proc.new { |n| raise Capybara::Poltergeist::BrowserError, 'Exception' }
      expect{ crawler.crawl(page, block) }.to_not raise_error
      expect(page.status).to eq(404)
    end

    it 'logs interesting information' do
      crawler
      expect(Grell.logger).to receive(:info).with(/Visiting #{url}, visited_links: 0, discovered 0/)
      crawler.crawl(page, nil)
    end

    it 'retries when the block returns :retry' do
      counter = 0
      times_retrying = 2
      block = Proc.new do |n|
        if counter < times_retrying
          counter += 1
          :retry
        end
      end
      crawler.crawl(page, block)
      expect(counter).to eq(times_retrying)
    end

    it 'handles redirects by adding the current_url to the page collection' do
      redirect_url = 'http://www.example.com/test/landing_page'
      allow(page).to receive(:current_url).and_return(redirect_url)
      expect_any_instance_of(Grell::PageCollection).to receive(:create_page).with(redirect_url, page_id)
      crawler.crawl(page, nil)
    end

    context 'without script' do
      it 'does not evaluate a script' do
        expect_any_instance_of(Capybara::Session).not_to receive(:evaluate_script)
        crawler.crawl(page, nil)
      end
    end

    context 'with script' do
      let(:script) { "(typeof(jQuery)!='undefined') && $('.dropdown').addClass('open');" }
      it 'evaluates a script' do
        expect_any_instance_of(Capybara::Session).to receive(:evaluate_script).with(script)
        crawler.crawl(page, nil)
      end
    end
  end

  context '#start_crawling' do
    let(:body) do
      <<-EOS
      <html><head></head><body>
      <a href="/musmis.html">trusmis</a>
      Hello world!
      </body></html>
      EOS
    end
    let(:url_visited) { "http://www.example.com/musmis.html" }

    before do
      proxy.stub(url_visited).and_return(body: 'body', code: 200)
    end

    it 'calls the block we used to start_crawling' do
      result = []
      block = Proc.new { |n| result.push(n) }
      crawler.start_crawling(url, &block)
      expect(result.size).to eq(2)
      expect(result[0].url).to eq(url)
      expect(result[1].url).to eq(url_visited)
    end

  end

  shared_examples_for 'visits all available pages' do
    it 'visits all the pages' do
      crawler.start_crawling(url)
      expect(crawler.collection.visited_pages.size).to eq(visited_pages_count)
    end

    it 'has no more pages to discover' do
      crawler.start_crawling(url)
      expect(crawler.collection.discovered_pages.size).to eq(0)
    end

    it 'contains the whitelisted page and the base page only' do
      crawler.start_crawling(url)
      expect(crawler.collection.visited_pages.map(&:url)).
        to eq(visited_pages)
    end
  end

  context 'the url has no links' do
    let(:body) do
      "<html><head></head><body>
      Hello world!
      </body></html>"
    end
    let(:visited_pages_count) { 1 }
    let(:visited_pages) { ['http://www.example.com/test'] }

    it_behaves_like 'visits all available pages'
  end

  context 'the url has several links' do
    let(:visited_pages_count) { 3 }
    let(:visited_pages) do
      ['http://www.example.com/test', 'http://www.example.com/trusmis.html', 'http://www.example.com/help.html']
    end
    let(:body) do
      "<html><head></head><body>
      <a href=\"/trusmis.html\">trusmis</a>
      <a href=\"/help.html\">help</a>
      Hello world!
      </body></html>"
    end

    before do
      proxy.stub('http://www.example.com/trusmis.html').and_return(body: 'body', code: 200)
      proxy.stub('http://www.example.com/help.html').and_return(body: 'body', code: 200)
    end

    it_behaves_like 'visits all available pages'
  end

  describe '#whitelist' do
    let(:body) do
      "<html><head></head><body>
      <a href=\"/trusmis.html\">trusmis</a>
      <a href=\"/help.html\">help</a>
      Hello world!
      </body></html>"
    end

    before do
      proxy.stub('http://www.example.com/trusmis.html').and_return(body: 'body', code: 200)
      proxy.stub('http://www.example.com/help.html').and_return(body: 'body', code: 200)
    end

    context 'using a single string' do
      let(:whitelist) { '/trusmis.html' }
      let(:visited_pages_count) { 2 } # my own page + trusmis
      let(:visited_pages) do
        ['http://www.example.com/test', 'http://www.example.com/trusmis.html']
      end

      it_behaves_like 'visits all available pages'
    end

    context 'using an array of strings' do
      let(:whitelist) { ['/trusmis.html', '/nothere', 'another.html'] }
      let(:visited_pages_count) { 2 }
      let(:visited_pages) do
        ['http://www.example.com/test', 'http://www.example.com/trusmis.html']
      end

      it_behaves_like 'visits all available pages'
    end

    context 'using a regexp' do
      let(:whitelist) { /\/trusmis\.html/ }
      let(:visited_pages_count) { 2 }
      let(:visited_pages) do
        ['http://www.example.com/test', 'http://www.example.com/trusmis.html']
      end

      it_behaves_like 'visits all available pages'
    end

    context 'using an array of regexps' do
      let(:whitelist) { [/\/trusmis\.html/] }
      let(:visited_pages_count) { 2 }
      let(:visited_pages) do
        ['http://www.example.com/test', 'http://www.example.com/trusmis.html']
      end

      it_behaves_like 'visits all available pages'
    end

    context 'using an empty array' do
      let(:whitelist) { [] }
      let(:visited_pages_count) { 1 } # my own page only
      let(:visited_pages) do
        ['http://www.example.com/test']
      end

      it_behaves_like 'visits all available pages'
    end

    context 'adding all links to the whitelist' do
      let(:whitelist) { ['/trusmis', '/help'] }
      let(:visited_pages_count) { 3 } # all links
      let(:visited_pages) do
        ['http://www.example.com/test','http://www.example.com/trusmis.html', 'http://www.example.com/help.html']
      end

      it_behaves_like 'visits all available pages'
    end
  end


  describe '#blacklist' do
    let(:body) do
      "<html><head></head><body>
      <a href=\"/trusmis.html\">trusmis</a>
      <a href=\"/help.html\">help</a>
      Hello world!
      </body></html>"
    end

    before do
      proxy.stub('http://www.example.com/trusmis.html').and_return(body: 'body', code: 200)
      proxy.stub('http://www.example.com/help.html').and_return(body: 'body', code: 200)
    end

    context 'using a single string' do
      let(:blacklist) { '/trusmis.html' }
      let(:visited_pages_count) {2}
      let(:visited_pages) do
        ['http://www.example.com/test','http://www.example.com/help.html']
      end

      it_behaves_like 'visits all available pages'
    end

    context 'using an array of strings' do
      let(:blacklist) { ['/trusmis.html', '/nothere', 'another.html'] }
      let(:visited_pages_count) {2}
      let(:visited_pages) do
        ['http://www.example.com/test','http://www.example.com/help.html']
      end

      it_behaves_like 'visits all available pages'
    end

    context 'using a regexp' do
      let(:blacklist) { /\/trusmis\.html/ }
      let(:visited_pages_count) {2}
      let(:visited_pages) do
        ['http://www.example.com/test','http://www.example.com/help.html']
      end

      it_behaves_like 'visits all available pages'
    end

    context 'using an array of regexps' do
      let(:blacklist) { [/\/trusmis\.html/] }
      let(:visited_pages_count) {2}
      let(:visited_pages) do
        ['http://www.example.com/test','http://www.example.com/help.html']
      end

      it_behaves_like 'visits all available pages'
    end

    context 'using an empty array' do
      let(:blacklist) { [] }
      let(:visited_pages_count) { 3 } # all links
      let(:visited_pages) do
        ['http://www.example.com/test','http://www.example.com/trusmis.html', 'http://www.example.com/help.html']
      end

      it_behaves_like 'visits all available pages'
    end

    context 'adding all links to the blacklist' do
      let(:blacklist) { ['/trusmis', '/help'] }
      let(:visited_pages_count) { 1 }
      let(:visited_pages) do
        ['http://www.example.com/test']
      end

      it_behaves_like 'visits all available pages'
    end
  end


  describe 'Whitelisting and blacklisting' do
    let(:body) do
      "<html><head></head><body>
      <a href=\"/trusmis.html\">trusmis</a>
      <a href=\"/help.html\">help</a>
      Hello world!
      </body></html>"
    end

    before do
      proxy.stub('http://www.example.com/trusmis.html').and_return(body: 'body', code: 200)
      proxy.stub('http://www.example.com/help.html').and_return(body: 'body', code: 200)
    end

    context 'we blacklist the only whitelisted page' do
      let(:whitelist) { '/trusmis.html' }
      let(:blacklist) { '/trusmis.html' }
      let(:visited_pages_count) { 1 }
      let(:visited_pages) do
        ['http://www.example.com/test']
      end

      it_behaves_like 'visits all available pages'
    end

    context 'we blacklist none of the whitelisted pages' do
      let(:whitelist) { '/trusmis.html' }
      let(:blacklist) { '/raistlin.html' }
      let(:visited_pages_count) { 2 }
      let(:visited_pages) do
        ['http://www.example.com/test', 'http://www.example.com/trusmis.html']
      end

      it_behaves_like 'visits all available pages'
    end
  end


end
