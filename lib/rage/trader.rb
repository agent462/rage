require 'json'

module Rage
  class Trader
    include Logging

    def initialize
      @mtgox = MtGox.new
    end

    def buy
      can_buy = @mtgox.can_buy
      amount = can_buy > Config.max_buy.to_f ? Config.max_buy.to_f : can_buy
      if amount < 0.01
        logger.info('The number of btc you can buy is below the minimum 0.01.')
        return
      end
      price = @mtgox.current_price
      total = amount.to_f * price.to_f
      logger.info("Attempting to buy #{amount} bitcoins at $#{price} for a total of $#{total}.")
      bid = @mtgox.buy!(amount, :market)
      sleep(5) while @mtgox.buys.count > 0
      order = @mtgox.order_result('bid', bid)
      logger.info("Bought #{order.total_amount.to_f} btc for $#{order.total_spent.to_f} with an average cost of $#{order.avg_cost.to_f}.")
      save_trade({
          :id => order.id,
          :total_amount => order.total_amount,
          :avg_cost => order.avg_cost,
          :total => order.total_spent
        }, 'bid')
    end

    def sell
      btc = @mtgox.get_btc_balance
      btc > Config.max_sell.to_f ? amount = Config.max_sell.to_f : amount = btc
      ask = @mtgox.sell!(amount, :market)
      logger.info("Attempting to sell #{amount} bitcoins.")
      sleep(5) while @mtgox.sells.count > 0
      order = @mtgox.order_result('ask', ask)
      logger.info("Sold #{order.total_amount.to_f} btc for $#{order.total_spent.to_f} with an average price of $#{order.avg_cost.to_f}.")
      save_trade({
          :id => order.id,
          :total_amount => order.total_amount,
          :avg_cost => order.avg_cost,
          :total => order.total_spent
        }, 'ask')
    end

    def save_trade(order, type)
      trade = {
        :id => order[:id],
        :type => type,
        :amount => order[:total_amount],
        :price => order[:avg_cost],
        :total => order[:total_spent]
      }
      redis = Redis.new(:host => Config.redis_host, :port => Config.redis_port)
      redis.sadd('trades', trade[:id])
      redis.set("trade:#{trade[:id]}", trade.to_json)
      logger.debug('Trade has been saved.')
    end

    def calculate_profits
    end

  end
end
