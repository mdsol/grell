
RSpec.describe Grell::Crawler do
  let(:page_id) { rand(10).floor + 10}
  let(:parent_page_id) {rand(10).floor}
  let(:page) {Grell::Page.new(url, page_id, parent_page_id)}
  let(:host) {"http://www.example.com"}
  let(:url) {"http://www.example.com/test"}
  let(:crawler) { Grell::Crawler.new(external_driver: true)}
  let(:body) {'body'}

  before do
    proxy.stub(url).and_return(body: body, code: 200)
  end

  describe 'initialize' do
    it 'can provide your own logger' do
      Grell::Crawler.new(external_driver: true, logger: 33)
      expect(Grell.logger).to eq(33)
    end
    it 'provides a stdout logger if nothing provided' do
      crawler
      expect(Grell.logger).to be_instance_of(Logger)
    end
  end

  context '#crawl' do
    it 'yields the result if a block is given' do
      result = []
      block = Proc.new {|n| result.push(n) }
      crawler.crawl(page, block)
      expect(result.size).to eq(1)
      expect(result.first.url).to eq(url)
      expect(result.first.visited?).to eq(true)
    end

    it 'logs interesting information' do
      crawler
      expect(Grell.logger).to receive(:info).with(/Visiting #{url}, visited_links: 0, discovered 0/)
      crawler.crawl(page, nil)
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
    let(:url_visited) {"http://www.example.com/musmis.html"}
    before do
      proxy.stub(url_visited).and_return(body: 'body', code: 200)
    end

    it 'calls the block we used to start_crawling' do
      result = []
      block = Proc.new {|n| result.push(n) }
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
    let(:visited_pages_count) {1}
    let(:visited_pages) {['http://www.example.com/test']}

    it_behaves_like 'visits all available pages'
  end

  context 'the url has several links' do
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
    let(:visited_pages_count) {3}
    let(:visited_pages) do
      ['http://www.example.com/test','http://www.example.com/trusmis.html', 'http://www.example.com/help.html']
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
      before do
        crawler.whitelist('/trusmis.html')
      end
      let(:visited_pages_count) {2} #my own page + trusmis
      let(:visited_pages) do
        ['http://www.example.com/test','http://www.example.com/trusmis.html']
      end

      it_behaves_like 'visits all available pages'
    end

    context 'using an array of strings' do
      before do
        crawler.whitelist(['/trusmis.html', '/nothere', 'another.html'])
      end
      let(:visited_pages_count) {2}
      let(:visited_pages) do
        ['http://www.example.com/test','http://www.example.com/trusmis.html']
      end

      it_behaves_like 'visits all available pages'
    end

    context 'using a regexp' do
      before do
        crawler.whitelist(/\/trusmis\.html/)
      end
      let(:visited_pages_count) {2}
      let(:visited_pages) do
        ['http://www.example.com/test','http://www.example.com/trusmis.html']
      end

      it_behaves_like 'visits all available pages'
    end

    context 'using an array of regexps' do
      before do
        crawler.whitelist([/\/trusmis\.html/])
      end
      let(:visited_pages_count) {2}
      let(:visited_pages) do
        ['http://www.example.com/test','http://www.example.com/trusmis.html']
      end

      it_behaves_like 'visits all available pages'
    end

    context 'using an empty array' do
      before do
        crawler.whitelist([])
      end
      let(:visited_pages_count) {1} #my own page only
      let(:visited_pages) do
        ['http://www.example.com/test']
      end

      it_behaves_like 'visits all available pages'
    end

    context 'adding all links to the whitelist' do
      before do
        crawler.whitelist(['/trusmis', '/help'])
      end
      let(:visited_pages_count) {3} #all links
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
      before do
        crawler.blacklist('/trusmis.html')
      end
      let(:visited_pages_count) {2}
      let(:visited_pages) do
        ['http://www.example.com/test','http://www.example.com/help.html']
      end

      it_behaves_like 'visits all available pages'
    end

    context 'using an array of strings' do
      before do
        crawler.blacklist(['/trusmis.html', '/nothere', 'another.html'])
      end
      let(:visited_pages_count) {2}
      let(:visited_pages) do
        ['http://www.example.com/test','http://www.example.com/help.html']
      end

      it_behaves_like 'visits all available pages'
    end

    context 'using a regexp' do
      before do
        crawler.blacklist(/\/trusmis\.html/)
      end
      let(:visited_pages_count) {2}
      let(:visited_pages) do
        ['http://www.example.com/test','http://www.example.com/help.html']
      end

      it_behaves_like 'visits all available pages'
    end

    context 'using an array of regexps' do
      before do
        crawler.blacklist([/\/trusmis\.html/])
      end
      let(:visited_pages_count) {2}
      let(:visited_pages) do
        ['http://www.example.com/test','http://www.example.com/help.html']
      end

      it_behaves_like 'visits all available pages'
    end

    context 'using an empty array' do
      before do
        crawler.blacklist([])
      end
      let(:visited_pages_count) {3} #all links
      let(:visited_pages) do
        ['http://www.example.com/test','http://www.example.com/trusmis.html', 'http://www.example.com/help.html']
      end

      it_behaves_like 'visits all available pages'
    end

    context 'adding all links to the whitelist' do
      before do
        crawler.blacklist(['/trusmis', '/help'])
      end
      let(:visited_pages_count) {1}
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
      before do
        crawler.whitelist('/trusmis.html')
        crawler.blacklist('/trusmis.html')
      end
      let(:visited_pages_count) {1}
      let(:visited_pages) do
        ['http://www.example.com/test']
      end

      it_behaves_like 'visits all available pages'
    end

    context 'we blacklist none of the whitelisted pages' do
      before do
        crawler.whitelist('/trusmis.html')
        crawler.blacklist('/raistlin.html')
      end
      let(:visited_pages_count) {2}
      let(:visited_pages) do
        ['http://www.example.com/test', 'http://www.example.com/trusmis.html']
      end

      it_behaves_like 'visits all available pages'
    end
  end


end
