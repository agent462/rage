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
        trades = redis.smembers('trades:mock')
        trades.each do |trade|
          list.push(JSON.parse(redis.get("trade:mock:#{trade}"), :symbolize_names => true))
        end
        list
      end

    end
  end
end
