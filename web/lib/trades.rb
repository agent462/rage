require 'redis'
require 'json'

module Rage
  module WebStack
    class Trades

      def redis
        @redis ||= ::Redis.new(:host => '127.0.0.1', :port => '6379')
      end

      def get_trades
        list = []
        trades = redis.smembers('mock:trades')
        trades.each do |trade|
          list.push(JSON.parse(redis.get("mock:trade:#{trade}"), :symbolize_names => true))
        end
        list.sort_by { |hsh| hsh[:id] }.reverse
      end

    end
  end
end
