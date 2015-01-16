module Grell
  class Reader
    def self.wait_for(action, max_waiting, sleeping_time)
      time_start = self.current_time
      action.call()
      return if yield
      while (self.current_time < time_start + max_waiting)
        action.call()
        break if yield
        sleep(sleeping_time)
      end
    end

    def self.current_time
      Time.now
    end

  end
end