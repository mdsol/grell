
RSpec.describe Grell::PageCollection do
  let(:collection) {Grell::PageCollection.new}

  context 'empty collection' do

    it 'has no visited pages' do
      expect(collection.visited_pages).to be_empty
    end

    it 'has no discovered pages' do
      expect(collection.discovered_pages).to be_empty
    end

    it 'next page is nil' do
      expect(collection.next_page).to be_nil
    end
  end

  context 'one unvisited page' do
    let(:page) {collection.create_page('url', 0)}
    before do
      page.visited = false
    end

    it 'has no visited pages' do
      expect(collection.visited_pages).to be_empty
    end

    it 'has one discovered page' do
      expect(collection.discovered_pages).to eq([page])

    end

    it 'next page is the unvisited page' do
      expect(collection.next_page).to eq(page)
    end
  end

  context 'one visited page' do
    let(:page) {collection.create_page('url', 0)}
    before do
      page.visited = true
    end

    it 'has one visited page' do
      expect(collection.visited_pages).to eq([page])
    end

    it 'has no discovered pages' do
      expect(collection.discovered_pages).to be_empty
    end

    it 'next page is nil' do
      expect(collection.next_page).to be_nil
    end
  end

  context 'one visited and one unvisited page with the same url' do
    let(:page) {collection.create_page('url', 0)}
    let(:unvisited)  {collection.create_page('url', 0)}
    before do
      page.visited = true
      unvisited.visited = false
    end

    it 'first page has id 0' do
      expect(page.id).to eq(0)
    end

    it 'second page has id 1' do
      expect(unvisited.id).to eq(1)
    end

    it 'has one visited page' do
      expect(collection.visited_pages).to eq([page])
    end

    it 'has no discovered pages' do
      expect(collection.discovered_pages).to be_empty
    end

    it 'next page is nil' do
      expect(collection.next_page).to be_nil
    end
  end

  context 'one visited and one unvisited page with different URLs' do
    let(:page) {collection.create_page('url', 0)}
    let(:unvisited)  {collection.create_page('url2', 0)}
    before do
      page.visited = true
      unvisited.visited = false
    end

    it 'has one visited page' do
      expect(collection.visited_pages).to eq([page])
    end

    it 'has one discovered page' do
      expect(collection.discovered_pages).to eq([unvisited])
    end

    it 'next page is the unvisited page' do
      expect(collection.next_page).to eq(unvisited)
    end
  end

  context 'several unvisited pages' do
    let(:page) {collection.create_page('url', 2)}
    let(:page2) {collection.create_page('url2', 0)}
    before do
      page.visited = false
      page2.visited = false
    end

    it "returns the page which has an earlier parent" do
      expect(collection.next_page).to eq(page2)
    end

  end



end