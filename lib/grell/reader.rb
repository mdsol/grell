module Grell
  class Reader
    def self.wait_for(action, max_waiting, sleeping_time)
      time_start = Time.now
      action.call()
      return if yield
      while (Time.now < time_start + max_waiting)
        action.call()
        break if yield
        sleep(sleeping_time)
      end
    end
  end
end