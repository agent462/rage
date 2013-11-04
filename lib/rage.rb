require 'redis'
require 'rage/core/log'
require 'rage/base'
require 'rage/core/settings'
require 'rage/core/email'
require 'rage/scheduler'
require 'rage/version'
require 'rage/aggregator'
require 'rage/trader'
require 'rage/stats'
require 'rage/decision'
Dir[File.dirname(__FILE__) + '/rage/indicators/*.rb'].each { |file| require file }

module Rage
  def self.redis
    @redis ||= Redis.new(:host => Config.redis_host, :port => Config.redis_port)
  end
end
