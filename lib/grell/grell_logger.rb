require 'logger'

#Very simple global logger for our crawler.
module Grell
  class << self
    attr_accessor :logger
  end
end

Grell.logger = Logger.new(STDOUT)