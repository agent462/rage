require 'mtgox'
require 'bigdecimal/util'

module Rage
  class MtGox

    def initialize
      ::MtGox.configure do |config|
        config.key = Config.mtgox_key
        config.secret = Config.mtgox_secret
      end
    end

    def current_price
      d = ::MtGox.ticker.sell
      d.to_digits
    end

    def get_asks
      asks = ::MtGox.asks
      asks[0].each do |ask|
        pp ask.price
      end
    end

    def buy(count)
      ::MtGox.buy! count, :market
    end

    def get_buys
      ::MtGox.buys
    end

    def get_sells
      ::MtGox.sells
    end

    def order_result(type, id)
      ::MtGox.order_result(type, id)
    end

    def sell(count)
      ::MtGox.sell! count, :market
    end

    def get_bids
      ::MtGox.bids
    end

    def can_buy
      balance = get_usd_balance.to_f
      Integer(((balance - (commission(balance))) / current_price.to_f) * 100) / Float(100)
    end

    def commission(balance)
      (balance * Config.commission) / 100
    end

    def has_money?
      balance = get_balance
      balance['USD'].to_f > 0 ? true : false
    end

    def has_btc?
      balance = get_balance
      balance['BTC'].to_f > 0 ? true : false
    end

    def get_usd_balance
      balance = get_balance
      balance['USD']
    end

    def get_btc_balance
      balance = get_balance
      balance['BTC'].to_f
    end

    def get_balance
      balance = {}
      response = ::MtGox.balance
      response.each do |res|
        balance[res.currency] = res.amount.to_digits
      end
      balance
    end

    def get_trades(hash = false)
      if hash
        ::MtGox.trades(hash)
      else
        ::MtGox.trades
      end
    end

  end
end
