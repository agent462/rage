require 'mtgox'
require 'bigdecimal/util'

module Rage
  class MtGox

    def initialize
      ::MtGox.configure do |config|
        config.key = Config.mtgox_key
        config.secret = Config.mtgox_secret
      end
      @logger = Rage.logger
    end

    def current_price
      d = ::MtGox.ticker.price
      d.to_digits
    end

    def get_asks
      asks = ::MtGox.asks
      asks[0].each do |ask|
        pp ask.price
      end
    end

    def buy
      ::MtGox.buy! count, :market
    end

    def sell(count)
      ::MtGox.sell! count, :market
    end

    def get_bids
      ::MtGox.bids
    end

    def has_money?
      balance = get_balance
      balance['USD'].to_f > 0 ? true : false
    end

    def has_btc?
      balance = get_balance
      balance['BTC'].to_f > 0 ? true : false
    end

    def get_balance
      balance = {}
      response = ::MtGox.balance
      response.each do |res|
        balance[res.currency] = res.amount.to_digits
      end
      balance
    end

    def get_trades
      trades = ::MtGox.trades
      @logger.info("Fetched #{trades.count} trades.")
      agg = Aggregator.new
      agg.save_trades(trades)
    end

  end
end
