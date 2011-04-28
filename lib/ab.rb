$LOAD_PATH << File.dirname(__FILE__)

require "ab/test"
require "ab/interface"
require "ab/alternative"

module AB
  VERSION = "0.0.1"

  def self.redis=(redis)
    @redis = redis
  end

  def self.redis
    @redis ||= Redis.new
  end
end
