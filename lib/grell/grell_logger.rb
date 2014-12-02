require 'logger'

#Very simple global logger for our crawler.
module Grell
  Log = Logger.new(STDOUT)
end