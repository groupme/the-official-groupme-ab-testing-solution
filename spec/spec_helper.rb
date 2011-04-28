require "redis"
require 'yaml'

require File.join(File.dirname(__FILE__), *%w[.. lib ab])

alias running proc
