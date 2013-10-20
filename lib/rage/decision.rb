module Rage
  class Decision

    def initialize
      base = Base.new
      @logger = base.logger
    end

    def make(advice)
      mtgox = MtGox.new
      if advice == 'buy'
        if mtgox.has_btc?
          @logger.info('We already own btc.  Not buying.')
        else
          @logger.info('I am buying.')
          # trade = Trader.new
          # trade.buy
        end
      elsif advice == 'sell'
        if mtgot.has_btc?
          @logger.info('I am selling.')
          # trade = Trader.new
          # trade.sell
        else
          @logger.info("We don't own any btc to sell.  Not doing anything")
        end
      else
        @logger.info('The suggestion is to hold.  We are not performing a trade at this time.')
      end
      email(advice)
    end

    def email(advice)
      Email::send_email(:advice => advice, :message => 'todo')
    end

  end
end
