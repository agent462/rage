require 'json'
require 'rage/mock_account'

module Rage
  class Trader
    include Logging

    def initialize
      @mtgox = MtGox.new
      @account = MockAccount.new if is_mock?
      @price = @mtgox.current_price
    end

    def buy
      amount = buy_amount
      return logger.info('The number of btc you can buy is below the minimum 0.01.') if amount < 0.01
      total = total(@price, amount)
      logger.info("Attempting to buy #{amount} bitcoins at $#{@price} for a total of $#{total}.")
      if is_mock?
        logger.info('Making a paper buy trade.')
        save_trade(mock_trade(Time.now.to_i, 'buy', amount, @price, total))
        @account.save_btc(amount)
        @account.save_balance(0)
      else
        bid = @mtgox.buy!(amount, :market)
        sleep(5) while @mtgox.buys.count > 0
        order = @mtgox.order_result('bid', bid)
        save_trade(mock_trade(order.id, 'buy', order.total_amount, order.avg_cost, order.total_spent))
      end
    end

    def is_mock?
      @is_mock ||= !Config.trade
    end

    def total(price, amount)
      Integer(((amount.to_f * price.to_f)) * 100000) / Float(100000)
    end

    def buy_amount
      can_buy = is_mock? ? @account.can_buy(@price) : @mtgox.can_buy
      (Config.max_buy.nil? || can_buy <= Config.max_buy.to_f) ? can_buy.to_f : Config.max_buy.to_f
    end

    def sell
      amount = sell_amount
      return logger.info('The number of bitcon you have to sell is below the minimum .01') if amount < 0.01
      logger.info("Attempting to sell #{amount} bitcoins.")
      if is_mock?
        logger.info('Making a paper sell trade.')
        total = total(@price, amount)
        save_trade(mock_trade(Time.now.to_i, 'sell', amount, @price, total))
        @account.save_btc(0)
        @account.save_balance(total)
      else
        ask = @mtgox.sell!(amount, :market)
        sleep(5) while @mtgox.sells.count > 0
        order = @mtgox.order_result('ask', ask)
        save_trade(mock_trade(order.id, order.total_amount, order.avg_cost, order.total_spent))
      end
    end

    def sell_amount
      can_sell = is_mock? ? @account.btc : @mtgox.get_btc_balance
      (Config.max_sell.nil? || can_sell <= Config.max_sell.to_f) ? can_sell.to_f : Config.max_sell.to_f
    end

    def save_trade(trade)
      if is_mock?
        Rage.redis.sadd('mock:trades', trade[:id])
        Rage.redis.set("mock:trade:#{trade[:id]}", trade.to_json)
      else
        Rage.redis.sadd('trades', trade[:id])
        Rage.redis.set("trade:#{trade[:id]}", trade.to_json)
      end
      logger.debug('Trade has been saved.')
    end

    def mock_trade(id, type, amount, price, total)
      if type == 'buy'
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

  end
end
