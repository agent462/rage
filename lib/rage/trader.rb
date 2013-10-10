require 'json'

module Rage
  class Trader

    def initialize
      @logger = Rage.logger
      @mtgox = MtGox.new
    end

    def buy
      buy = @mtgox.can_buy
      price = @mtgox.current_price
      total = buy * price
      @mtgox.buy(buy, price)
      @logger.info("Attempting to buy #{buy} bitcoins at $#{price} for a total of $#{total}.")
      #save_trade(purchase)
    end

    def sell
      btc = @mtgox.get_btc_balance
      @mtgox.sell(btc)
      @logger.info("Sold #{btc} bitcoins.")
      #save_trade(purchase)
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
      redis = Redis.new(:host => Config.redis_host, :port => Config.redis_port)
      redis.sadd('trades', trade.to_json)
      @logger.info("Trade has been saved.")
    end

  end
end
