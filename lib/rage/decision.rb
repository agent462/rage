module Rage
  class Decision
    include Logging
    attr_reader :account, :trade

    def initialize(account)
      @account = account
      @trade = Trader.new
    end

    def make(advice)
      if advice[:advice] == 'buy'
        if account.has_btc?
          logger.info('We already own btc.  Not buying.')
        else
          logger.info('I am buying.')
          trade.buy
        end
      elsif advice[:advice] == 'sell'
        if account.has_btc?
          logger.info('I am selling.')
          trade.sell
        else
          logger.info("We don't own any btc to sell.  Not doing anything")
        end
      else
        logger.info('The suggestion is to hold.  We are not performing a trade at this time.')
      end
      email(advice)
    end

    def email(advice)
      Email::send_email(:subject => "Rage Trader:  Recommendation is to #{advice[:advice]}", :body => 'todo') unless advice[:current] == advice[:previous]
    end

  end
end
