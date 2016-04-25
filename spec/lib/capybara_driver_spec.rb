
RSpec.describe Grell::CapybaraDriver do
  let(:ts) { Time.now }

  describe 'setup_capybara' do
    it 'properly registers the poltergeist driver' do
      Timecop.freeze(ts)
      driver = Grell::CapybaraDriver.new.setup_capybara
      expect(driver).to be_instance_of(Capybara::Poltergeist::Driver)
    end

    it 'raises an exception if the driver cannot be initialized' do
      Timecop.freeze(ts + 60)

      # Attempt to register twice with the same driver name
      Grell::CapybaraDriver.new.setup_capybara
      expect { Grell::CapybaraDriver.new.setup_capybara }.
        to raise_error "Poltergeist Driver could not be properly initialized"
    end

    it 'can register the poltergeist driver multiple times in a row' do
      Timecop.freeze(ts + 120)
      driver = Grell::CapybaraDriver.new.setup_capybara
      expect(driver).to be_instance_of(Capybara::Poltergeist::Driver)
    end
  end

  describe 'quit' do
    let(:driver) { Grell::CapybaraDriver.new.setup_capybara }
    it 'quits the poltergeist driver' do
      expect_any_instance_of(Capybara::Poltergeist::Driver).to receive(:quit)
      driver.quit
    end
  end

  after do
    Timecop.return

    # Reset Capybara so future tests can easily stub HTTP requests
    Capybara.javascript_driver = :poltergeist_billy
    Capybara.default_driver = :poltergeist_billy
  end
end
