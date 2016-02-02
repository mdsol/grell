RSpec.describe Grell::Page do

  let(:page_id) { rand(10).floor + 10 }
  let(:parent_page_id) { rand(10).floor }
  let(:page) { Grell::Page.new(url, page_id, parent_page_id) }
  let(:host) { 'http://www.example.com' }
  let(:url) { 'http://www.example.com/test' }
  let(:returned_headers)  { { 'Other-Header' => 'yes', 'Content-Type' => 'text/html' }}
  let(:now) { Time.now }

  before do
    allow(Time).to receive(:now).and_return(now)
    Grell.logger = Logger.new(nil) # avoids noise in rspec output
  end

  it 'gives access to the url' do
    expect(page.url).to eq(url)
  end

  it 'gives access to the path' do
    expect(page.path).to eq('/test')
  end

  it 'gives access to the page id' do
    expect(page.id).to eq(page_id)
  end

  it 'gives access to the parent page id' do
    expect(page.parent_id).to eq(parent_page_id)
  end

  it 'newly created page does not have status yet' do
    expect(page.status).to eq(nil)
  end

  shared_examples_for 'a grell page' do

    it 'returns the correct status' do
      expect(page.status).to eq(status)
    end

    it 'has the correct body' do
      expect(page.body).to eq(body)
    end

    it 'has correct headers' do
      expect(page.headers).to include(expected_headers)
    end

    it 'has the correct links' do
      expect(page.links.sort).to eq(links.sort)
    end

    it '#visited? returns the correct value' do
      expect(page.visited?).to eq(visited)
    end

    it 'has correct timestamp' do
      expect(page.timestamp).to eq(now)
    end

  end

  describe '#retries' do
    context 'page has not been navigated' do
      it '#retries return 0' do
        expect(page.retries).to eq(0)
      end
    end

    context 'page has been navigated once' do
      before do
        proxy.stub(url).and_return(body: '', code: 200, headers: {})
        page.navigate
      end

      it '#retries return 0' do
        expect(page.retries).to eq(0)
      end
    end

    context 'page has been navigated twice' do
      before do
        proxy.stub(url).and_return(body: '', code: 200, headers: {})
        page.navigate
        page.navigate
      end

      it '#retries return 1' do
        expect(page.retries).to eq(1)
      end
    end
  end

  shared_examples_for 'an errored grell page' do
    it 'returns empty status 404 page after navigating' do
      expect(page.status).to eq(404)
      expect(page.links).to eq([])
      expect(page.headers).to eq(headers)
      expect(page.body).to eq('')
      expect(page.has_selector?('html')).to eq(false)
      expect(page).to be_visited
      expect(page.timestamp).to eq(now)
      expect(page.error?).to eq(true)
    end
  end

  [ Capybara::Poltergeist::JavascriptError, Capybara::Poltergeist::BrowserError, URI::InvalidURIError,
    Capybara::Poltergeist::TimeoutError, Capybara::Poltergeist::StatusFailError ].each do |error_type|

    context "#{error_type}" do
      let(:headers) do
        {
          grellStatus: 'Error',
          errorClass: "#{error_type}",
          errorMessage: error_message
        }
      end
      let(:error_message) { 'Trusmis broke it again' }
      let(:now) { Time.now }

      before do
        allow_any_instance_of(Grell::RawPage).to receive(:navigate).and_raise(error_type, 'error')
        allow_any_instance_of(error_type).to receive(:message).and_return(error_message)
        page.navigate
      end

      it_behaves_like 'an errored grell page'
    end
  end


  context 'we have not yet navigated to the page' do
    let(:visited) { false }
    let(:status) { nil }
    let(:body) { '' }
    let(:links) { [] }
    let(:expected_headers) { {} }
    let(:now) { nil }

    before do
      proxy.stub(url).and_return(body: body, code: status, headers: returned_headers.dup)
    end

    it_behaves_like 'a grell page'

  end

  context 'navigating to the URL we get a 404' do
    let(:visited) { true }
    let(:status) { 404 }
    let(:body) { '<html><head></head><body>nothing cool</body></html>' }
    let(:links) { [] }
    let(:expected_headers) { returned_headers }

    before do
      proxy.stub(url).and_return(body: body, code: status, headers: returned_headers.dup)
      page.navigate
    end

    it_behaves_like 'a grell page'

  end

  context 'navigating to an URL with redirects, follows them transparently' do
    let(:visited) { true }
    let(:status) { 200 }
    let(:body) { '<html><head></head><body>nothing cool</body></html>' }
    let(:links) { [] }
    let(:expected_headers) { returned_headers }
    let(:real_url) { 'http://example.com/other' }

    before do
      proxy.stub(url).and_return(:redirect_to => real_url)
      proxy.stub(real_url).and_return(body: body, code: status, headers: returned_headers.dup)
      page.navigate
    end

    it_behaves_like 'a grell page'

    it 'followed_redirects? is true' do
      expect(page.followed_redirects?).to eq(true)
    end

    it 'current_url match the url we were redirected to' do
      expect(page.current_url).to eq(real_url)
    end
  end

  #Here also add examples that may happen for almost all pages (no errors, no redirects)
  context 'navigating to the URL we get page with no links' do
    let(:visited) { true }
    let(:status) { 200 }
    let(:body) { '<html><head></head><body>nothing cool</body></html>' }
    let(:links) { [] }
    let(:expected_headers) { returned_headers }

    before do
      proxy.stub(url).and_return(body: body, code: status, headers: returned_headers.dup)
      page.navigate
    end

    it_behaves_like 'a grell page'

    it 'followed_redirects is false' do
      expect(page.followed_redirects?).to eq(false)
    end

    it 'current_url is url' do
      expect(page.current_url).to eq(url)
    end

    it 'does not have errors' do
      expect(page.error?).to eq(false)
    end
  end

  context 'navigating to the URL we get page with links using a elements' do
    let(:visited) { true }
    let(:status) { 200 }
    let(:body) do
      "<html><head></head><body>
      Hello world!
      <a href=\"/trusmis.html\">trusmis</a>
      <a href=\"/help.html\">help</a>
      <a href=\"http://www.outsidewebsite.com/help.html\">help</a>
      </body></html>"
    end
    let(:links) { ['http://www.example.com/trusmis.html', 'http://www.example.com/help.html'] }
    let(:expected_headers) { returned_headers }

    before do
      proxy.stub(url).and_return(body: body, code: status, headers: returned_headers.dup)
      page.navigate
    end

    it_behaves_like 'a grell page'

    it 'do not return links to external websites' do
      expect(page.links).to_not include('http://www.outsidewebsite.com/help.html')
    end
  end

  context 'navigating to the URL we get page with links with absolute links' do
    let(:visited) { true }
    let(:status) { 200 }
    let(:body) do
      "<html><head></head><body>
      Hello world!
      <a href=\"/trusmis.html\">trusmis</a>
      <a href=\"http://www.example.com/help.html\">help</a>
      <a href=\"http://www.outsidewebsite.com/help.html\">help</a>
      </body></html>"
    end
    let(:links) { ['http://www.example.com/trusmis.html', 'http://www.example.com/help.html'] }
    let(:expected_headers) { returned_headers }

    before do
      proxy.stub(url).and_return(body: body, code: status, headers: returned_headers.dup)
      page.navigate
    end

    it_behaves_like 'a grell page'

    it 'do not return links to external websites' do
      expect(page.links).to_not include('http://www.outsidewebsite.com/help.html')
    end
  end

  context 'navigating to the URL we get page with links using a mix of elements' do
    let(:visited) { true }
    let(:status) { 200 }
    let(:body) do
      "<html><head></head><body>
      Hello world!
      <a href=\"/trusmis.html\">trusmis</a>
      <table>
      <tbody>
      <tr href=\"/help_me.html\"><td>help</td></tr>
      <tr data-href=\"/help.html\"><td>help</td></tr>
      </tbody>
      </table>
      <div data-href=\"http://www.example.com/more_help.html\">help</div>
      <div data-href=\"http://www.outsidewebsite.com/help.html\">help</div>
      </body></html>"
    end
    let(:links) do
      [ 'http://www.example.com/trusmis.html', 'http://www.example.com/help.html',
        'http://www.example.com/more_help.html', 'http://www.example.com/help_me.html' ]
    end
    let(:expected_headers) { returned_headers }

    before do
      proxy.stub(url).and_return(body: body, code: status, headers: returned_headers.dup)
      page.navigate
    end

    it_behaves_like 'a grell page'

    describe '#path' do
      context 'proper url' do
        let(:url) { 'http://www.anyurl.com/path' }
        let(:page) { Grell::Page.new(url, page_id, parent_page_id) }

        it 'returns the path' do
          expect(page.path).to eq('/path')
        end
      end

      context 'broken url' do
        let(:url) { 'www.an.asda.fasfasf.yurl.com/path' }
        let(:page) { Grell::Page.new(url, page_id, parent_page_id) }

        it 'returns the path' do
          expect(page.path).to eq(url)
        end
      end
    end

    it 'do not return links to external websites' do
      expect(page.links).to_not include('http://www.outsidewebsite.com/help.html')
    end
  end

 context 'navigating to the URL we get page with links inside the header section of the code' do
    let(:visited) { true }
    let(:status) { 200 }
    let(:css) { '/application.css' }
    let(:favicon) { '/favicon.ico' }
    let(:body) do
      "<html><head>
      <title>mimi</title>
      <link href=\"#{css}\" rel=\"stylesheet\">
      <link href=\"#{favicon}\" rel=\"shortcut icon\" type=\"image/vnd.microsoft.icon\">
      </head>
      <body>
      Hello world!
      <a href=\"/trusmis.html\">trusmis</a>
      </body></html>"
    end
    let(:links) do
      ['http://www.example.com/trusmis.html']
    end
    let(:expected_headers) { returned_headers }

    before do
      proxy.stub(url).and_return(body: body, code: status, headers: returned_headers.dup)
      #We need to stub this or Phantomjs will get stuck trying to retrieve the resources
      proxy.stub(host + css).and_return(body: '', code: status)
      proxy.stub(host + favicon).and_return(body: '', code: status)
      page.navigate
    end

    it_behaves_like 'a grell page'

    it 'do not return links to resources in the header' do
      expect(page.links).to_not include('http://www.example.com/application.css')
    end

  end

  context 'status is never set' do #this may happen when there is nothing comming from the site
    before do
      stub_const('Grell::Page::WAIT_TIME', 0)
      allow_any_instance_of(Grell::RawPage).to receive(:status).and_return(nil)
      allow_any_instance_of(Grell::RawPage).to receive(:headers).and_return({})
      allow_any_instance_of(Grell::RawPage).to receive(:body).and_return('')
      proxy.stub(url).and_return(body: body, code: nil, headers: {})
      page.navigate
    end

    let(:visited) { true }
    let(:status) { nil }
    let(:body) { '' }
    let(:links) { [] }
    let(:expected_headers) { {} }

    it_behaves_like 'a grell page'
  end

end
