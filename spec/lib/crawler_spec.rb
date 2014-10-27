
RSpec.describe Grell::Crawler do
  let(:page_id) { rand(10).floor + 10}
  let(:parent_page_id) {rand(10).floor}
  let(:page) {Grell::Page.new(url, page_id, parent_page_id)}
  let(:host) {"http://www.example.com"}
  let(:url) {"http://www.example.com/test"}
  let(:crawler) { Grell::Crawler.new(external_driver: true)}
  let(:body) {'body'}

  before(:each) do
    proxy.stub(url).and_return(body: body, code: 200)
  end

  context '#crawl' do
    it 'yields the result if a block is given' do
      block = Proc.new {|n| n }
      expect(block).to receive(:call).with(page)
      crawler.crawl(page, block)
    end

    it 'logs interesting information' do
      expect(Grell::Log).to receive(:info).with(/Visiting #{url}, visited_links: 0, discovered 0/)
      crawler.crawl(page, nil)
    end
  end

  context '#start_crawling' do
    it 'calls the block we used to start_crawling' do
      block = Proc.new {|n| n }
      expect(block).to receive(:call)
      crawler.start_crawling(url, &block)
    end
  end

  context 'the url has no links' do
    let(:body) do
      "<html><head></head><body>
      Hello world!
      </body></html>"
    end
    before do
      crawler.start_crawling(url)
    end
    it 'visits all the pages' do
      expect(crawler.collection.visited_pages.size).to eq(1)
    end
    it 'has no more pages to discover' do
      expect(crawler.collection.discovered_pages.size).to eq(0)
    end
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

    it 'visits all the pages' do
      crawler.start_crawling(url)
      expect(crawler.collection.visited_pages.size).to eq(3)
    end
    it 'has no more pages to discover' do
      crawler.start_crawling(url)
      expect(crawler.collection.discovered_pages.size).to eq(0)
    end
  end


end