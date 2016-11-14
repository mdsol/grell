RSpec.describe Grell::CrawlerManager do
  let(:page) { Grell::Page.new(url, page_id, parent_page_id) }
  let(:host) { 'http://www.example.com' }
  let(:url) { 'http://www.example.com/test' }
  let(:driver) { nil }
  let(:logger) { Logger.new(nil) }
  let(:crawler_manager) do
    Grell::CrawlerManager.new(logger: logger, external_driver: true, driver: driver)
  end

  describe 'initialize' do
    it 'can provide your own logger' do
      described_class.new(external_driver: true, logger: 33)
      expect(Grell.logger).to eq(33)
      Grell.logger = Logger.new(nil)
    end

    it 'provides a stdout logger if no logger provided' do
      described_class.new(external_driver: true)
      expect(Grell.logger).to be_instance_of(Logger)
    end
  end

  describe '#quit' do
    let(:driver) { double }

    it 'quits the poltergeist driver' do
      expect(driver).to receive(:quit)
      crawler_manager.quit
    end
  end

  describe '#restart' do
    let(:driver) { double }

    it 'restarts the poltergeist driver' do
      expect(driver).to receive(:restart)
      expect(logger).to receive(:info).with("GRELL is restarting")
      expect(logger).to receive(:info).with("GRELL has restarted")
      crawler_manager.restart
    end
  end
  def check_periodic_restart(collection)
    if @periodic_restart_block && collection.visited_pages.size % @periodic_restart_period == 0
      restart
      @periodic_restart_block.call
    end
  end

  describe '#check_periodic_restart' do
    let(:collection) { double }
    context 'Periodic restart not setup' do
      it 'does not restart' do
        allow(collection).to receive_message_chain(:visited_pages, :size) { 100 }
        expect(crawler_manager).not_to receive(:restart)
        crawler_manager.check_periodic_restart(collection)
      end
    end
    context 'Periodic restart setup with default period' do
      let(:do_something) { Proc.new {} }
      let(:crawler_manager) do
        Grell::CrawlerManager.new(
          logger: logger,
          external_driver: true,
          driver: driver,
          on_periodic_restart: { do: do_something })
      end

      it 'does not restart after visiting 99 pages' do
        allow(collection).to receive_message_chain(:visited_pages, :size) { 99 }
        expect(crawler_manager).not_to receive(:restart)
        crawler_manager.check_periodic_restart(collection)
      end
      it 'restarts after visiting 100 pages' do
        allow(collection).to receive_message_chain(:visited_pages, :size) { 100 }
        expect(crawler_manager).to receive(:restart)
        crawler_manager.check_periodic_restart(collection)
      end
    end
    context 'Periodic restart setup with custom period' do
      let(:do_something) { Proc.new {} }
      let(:period) { 50 }
      let(:crawler_manager) do
        Grell::CrawlerManager.new(
          logger: logger,
          external_driver: true,
          driver: driver,
          on_periodic_restart: { do: do_something, each: period })
      end

      it 'does not restart after visiting a number different from custom period pages' do
        allow(collection).to receive_message_chain(:visited_pages, :size) { period * 1.2 }
        expect(crawler_manager).not_to receive(:restart)
        crawler_manager.check_periodic_restart(collection)
      end
      it 'restarts after visiting custom period pages' do
        allow(collection).to receive_message_chain(:visited_pages, :size) { period }
        expect(crawler_manager).to receive(:restart)
        crawler_manager.check_periodic_restart(collection)
      end
    end
  end

  describe '#cleanup_all_processes' do
    let(:driver) { double }

    it 'kills all phantomjs processes' do
      allow(crawler_manager).to receive(:running_phantomjs_pids).and_return([10])
      expect(crawler_manager).to receive(:kill_process).with(10)
      crawler_manager.cleanup_all_processes
    end
  end


end
