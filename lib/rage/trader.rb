require 'json'

module Rage
  class Trader
    include Logging

    def initialize
      @mtgox = MtGox.new
    end

    def buy
      amount = 0.2 # buy_amount
      return logger.info('The number of btc you can buy is below the minimum 0.01.') if amount < 0.01
      price = @mtgox.current_price
      total = amount.to_f * price.to_f
      logger.info("Attempting to buy #{amount} bitcoins at $#{price} for a total of $#{total}.")
      if Config.trade
        bid = @mtgox.buy!(amount, :market)
        sleep(5) while @mtgox.buys.count > 0
        order = @mtgox.order_result('bid', bid)
        save_trade(mock_trade(order.id, 'buy', order.total_amount, order.avg_cost, order.total_spent))
      else
        logger.info("Making a paper buy trade.")
        save_trade(mock_trade(Time.now.to_i, 'buy', amount, price, total))
      end
    end

    def buy_amount
      can_buy = @mtgox.can_buy
      (Config.max_buy.nil? || can_buy <= Config.max_buy.to_f) ? can_buy : Config.max_buy.to_f
    end

    def sell
      amount = sell_amount
      logger.info("Attempting to sell #{amount} bitcoins.")
      if Config.trade
        ask = @mtgox.sell!(amount, :market)
        sleep(5) while @mtgox.sells.count > 0
        order = @mtgox.order_result('ask', ask)
        save_trade(mock_trade(order.id, order.total_amount, order.avg_cost, order.total_spent))
      else
        logger.info("Making a paper sell trade.")
        price = @mtgox.current_price
        save_trade(mock_trade(Time.now.to_i, 'sell', amount, price, (price * amount)))
      end
    end

    def sell_amount
      btc = @mtgox.get_btc_balance
      (Config.max_sell.nil? || btc <= Config.max_sell.to_f) ? btc : Config.max_sell.to_f
    end

    def save_trade(trade)
      if Config.trade
        Rage.redis.sadd('trades', trade[:id])
        Rage.redis.set("trade:#{trade[:id]}", trade.to_json)
      else
        Rage.redis.sadd('trades:mock', trade[:id])
        Rage.redis.set("trade:mock:#{trade[:id]}", trade.to_json)
      end
      logger.debug('Trade has been saved.')
    end

    def mock_trade(id, type, amount, price, total)
      if type == "buy"
        logger.info("Bought #{amount.to_f} btc for $#{total.to_f} with an average cost of $#{price.to_f}.")
      else
        logger.info("Sold #{amount.to_f} btc for $#{total.to_f} with an average price of $#{price.to_f}.")
      end
      {
        :id => id,
        :type => type,
        :amount => amount,
        :price => price,
        :total => total
      }
    end

    def calculate_profits
    end

  end
end
