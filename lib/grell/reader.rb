module Grell
  # A tooling class, it waits a maximum of max_waiting for an action to finish. If the action is not
  # finished by them , we will continue anyway.
  # The wait may be long but we want to finish it as soon as the action has finished
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
