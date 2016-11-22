RSpec.describe Grell::CrawlerManager do
  let(:page) { Grell::Page.new(url, page_id, parent_page_id) }
  let(:host) { 'http://www.example.com' }
  let(:url) { 'http://www.example.com/test' }
  let(:driver) { double(Grell::CapybaraDriver) }
  let(:logger) { Logger.new(nil) }
  let(:crawler_manager) do
    described_class.new(logger: logger, driver: driver)
  end

  describe 'initialize' do
    context 'provides a logger' do
      let(:logger) { 33 }

      it 'sets custom logger' do
        crawler_manager
        expect(Grell.logger).to eq(33)
        Grell.logger = Logger.new(nil)
      end
    end

    context 'does not provides a logger' do
      let(:logger) { nil }

      it 'sets default logger' do
        crawler_manager
        expect(Grell.logger).to be_instance_of(Logger)
        Grell.logger = Logger.new(nil)
      end
    end

    context 'does not provide a driver' do
      let(:driver) { nil }

      it 'setups a new Capybara driver' do
        expect_any_instance_of(Grell::CapybaraDriver).to receive(:setup_capybara)
        crawler_manager
      end
    end
  end

  describe '#quit' do
    let(:driver) { double }

    it 'quits the poltergeist driver' do
      expect(logger).to receive(:info).with("GRELL. Driver quitting")
      expect(driver).to receive(:quit)
      crawler_manager.quit
    end
  end

  describe '#restart' do
    let(:driver) { double }

    it 'restarts the poltergeist driver' do
      expect(driver).to receive(:restart)
      expect(logger).to receive(:info).with("GRELL. Driver restarted")
      expect(logger).to receive(:info).with("GRELL. Driver restarting")
      crawler_manager.restart
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
      let(:do_something) { proc {} }
      let(:crawler_manager) do
        Grell::CrawlerManager.new(
          logger: logger,
          driver: driver,
          on_periodic_restart: { do: do_something }
        )
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
      let(:do_something) { proc {} }
      let(:period) { 50 }
      let(:crawler_manager) do
        Grell::CrawlerManager.new(
          logger: logger,
          driver: driver,
          on_periodic_restart: { do: do_something, each: period }
        )
      end

      context 'restart option is not positive' do
        let(:period) { 0 }

        it 'logs a warning' do
          message = 'GRELL. Restart option misconfigured with a negative period. Ignoring option.'
          expect(logger).to receive(:warn).with(message)
          crawler_manager
        end
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

  describe '.cleanup_all_processes' do
    let(:driver) { double }

    context 'There are some phantomjs processes running' do
      let(:pids) { [10, 11] }
      before do
        allow_any_instance_of(Grell::CrawlerManager::PhantomJSManager)
          .to receive(:running_phantomjs_pids).and_return(pids)
      end

      it 'logs processes pids' do
        expect(Grell.logger).to receive(:warn).with('GRELL. Killing PhantomJS processes: [10, 11]')
        expect(Grell.logger).to receive(:warn).with('GRELL. Sending KILL to PhantomJS process 10')
        expect(Grell.logger).to receive(:warn).with('GRELL. Sending KILL to PhantomJS process 11')
        described_class.cleanup_all_processes
      end

      it 'kills all phantomjs processes' do
        expect_any_instance_of(Grell::CrawlerManager::PhantomJSManager).to receive(:kill_process).with(10)
        expect_any_instance_of(Grell::CrawlerManager::PhantomJSManager).to receive(:kill_process).with(11)
        described_class.cleanup_all_processes
      end
    end

    context 'There are no phantomjs processes running' do
      let(:pids) { [] }
      before do
        allow_any_instance_of(Grell::CrawlerManager::PhantomJSManager)
          .to receive(:running_phantomjs_pids).and_return(pids)
      end

      it 'no warning is logged' do
        expect(Grell.logger).not_to receive(:warn)
        described_class.cleanup_all_processes
      end

      it 'No process is killed' do
        expect_any_instance_of(Grell::CrawlerManager::PhantomJSManager).not_to receive(:kill_process)
        described_class.cleanup_all_processes
      end
    end
  end
end
