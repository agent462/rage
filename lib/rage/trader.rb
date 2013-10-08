require 'json'

module Rage
  class Trader

    def initialize
      @logger = Rage.logger
    end

    def buy
      # go buy here
      @logger.info("Bought #{btc} bitcoins at $#{price} for a total of $#{total}.")
      save_trade(purchase)
    end

    def sell
      # go sell here
      @logger.info("Bought #{btc} bitcoins at $#{price} for a total of $#{total}.")
      save_trade(purchase)
    end

    def hold?
    end

    def save_trade(purchase)
      trade = {
        :timestamp => Time.now.to_i,
        :type => purchase[:type],
        :amount => purchase[:btc],
        :price => purchase[:price],
        :total => purchase[:btc] * purchase[:price]
      }
      redis = Redis.new(:host => "127.0.0.1", :port => 6379)
      redis.sadd('trades', trade.to_json)
      @logger.info("Trade has been saved.")
    end

  end
end
