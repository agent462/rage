require 'mtgox'
require 'bigdecimal/util'

module Rage
  class MtGox < MtGox::Client

    def initialize
      configure do |config|
        config.key = Config.mtgox_key
        config.secret = Config.mtgox_secret
      end
    end

    def can_buy
      balance = get_usd_balance.to_f
      Integer(((balance - (commission(balance))) / current_price.to_f) * 100) / Float(100)
    end

    def current_price
      ticker.sell.to_digits
    end

    def commission(balance)
      (balance * Config.commission) / 100
    end

    def has_money?
      get_balance['USD'].to_f > 0 ? true : false
    end

    def has_btc?
      get_balance['BTC'].to_f > 0 ? true : false
    end

    def get_usd_balance
      get_balance['USD']
    end

    def get_btc_balance
      get_balance['BTC'].to_f
    end

    def get_balance
      bal = {}
      balance.each do |res|
        bal[res.currency] = res.amount.to_digits
      end
      bal
    end

  end
end
