module Grell
  # Manages the state of the process crawling, does not care about individual pages but about logging,
  # restarting and quiting the crawler correctly.
  class CrawlerManager
    # logger: logger to use for Grell's messages
    # on_periodic_restart: if set, the driver will restart every :each visits (100 default) and execute the :do block
    # driver_options: Any extra options for the Capybara driver
    def initialize(logger: nil, on_periodic_restart: {}, driver: nil, **driver_options)
      Grell.logger = logger ? logger : Logger.new(STDOUT)
      @periodic_restart_block = on_periodic_restart[:do]
      @periodic_restart_period = on_periodic_restart[:each] || PAGES_TO_RESTART
      @driver = driver || CapybaraDriver.setup(driver_options)
      if @periodic_restart_period <= 0
        Grell.logger.warn "GRELL being misconfigured with a negative period to restart. Ignoring option."
      end
    end

    # Restarts the PhantomJS process without modifying the state of visited and discovered pages.
    def restart
      Grell.logger.info "GRELL is restarting"
      @driver.restart
      Grell.logger.info "GRELL has restarted"
    end

    # Quits the poltergeist driver.
    def quit
      Grell.logger.info "GRELL is quitting the poltergeist driver"
      @driver.quit
    end

    # PhantomJS seems to consume memory increasingly as it crawls, periodic restart allows to restart
    # the driver, potentially calling a block.
    def check_periodic_restart(collection)
      return unless @periodic_restart_block
      return unless @periodic_restart_period > 0
      return unless (collection.visited_pages.size % @periodic_restart_period).zero?
      restart
      @periodic_restart_block.call
    end

    def cleanup_all_processes
      pids = running_phantomjs_pids
      return if pids.empty?
      Grell.logger.warn "GRELL. Killing PhantomJS processes: #{pids.inspect}"
      pids.each do |pid|
        Grell.logger.warn "Sending KILL to PhantomJS process #{pid}"
        kill_process(pid.to_i)
      end
    end

    private

    PAGES_TO_RESTART = 100  # Default number of pages before we restart the driver.
    KILL_TIMEOUT = 2        # Number of seconds we wait till we kill the process.

    def running_phantomjs_pids
      list_phantomjs_processes_cmd = "ps -ef | grep -E 'bin/phantomjs' | grep -v grep"
      `#{list_phantomjs_processes_cmd} | awk '{print $2;}'`.split("\n")
    end

    def kill_process(pid)
      Process.kill('TERM', pid)
      force_kill(pid)
    rescue Errno::ESRCH, Errno::ECHILD
      # successfully terminated
    rescue => e
      Grell.logger.exception e, "PhantomJS process could not be killed"
    end

    def force_kill(pid)
      Timeout.timeout(KILL_TIMEOUT) { Process.wait(pid) }
    rescue Timeout::Error
      Process.kill('KILL', pid)
      Process.wait(pid)
    end
  end
end
