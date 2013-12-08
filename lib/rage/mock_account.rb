module Rage
  class MockAccount

    def balance
      if Rage.redis.exists('mock:account:balance')
        Rage.redis.get('mock:account:balance').to_f
      else
        save_balance(Config.mock_dollars || 1000)
        Config.mock_dollars.to_f
      end
    end

    def btc
      Rage.redis.exists('mock:account:btc') ? Rage.redis.get('mock:account:btc') : 0
    end

    def save_balance(balance)
      Rage.redis.set('mock:account:balance', balance)
    end

    def save_btc(btc)
      Rage.redis.set('mock:account:btc', btc)
    end

    def can_buy(current_price)
      Integer(((balance - commission) / current_price.to_f) * 100000000) / Float(100000000)
    end

    def has_btc?
      btc > 0 ? true : false
    end

    def commission
      (balance * Config.commission) / 100
    end

  end
end
