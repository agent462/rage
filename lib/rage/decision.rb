module Rage
  class Decision

    def make(results)
      mtgox = MtGox.new
      if results[:max] == "buy"
        if mtgox.has_btc?
          @logger.info("We already own btc.  Not buying.")
          trade = Trader.new
          trade.buy
        else
          @logger.info("I am buying.")
        end
      elsif results[:max] == "sell"
        if mtgot.has_btc?
          @logger.info("I am selling.")
          trade = Trader.new
          trade.sell
        else
          @logger.info("We don't own any btc to sell.  Not doing anything")
        end
      else
        @logger.info("Suggestion is to hold.  We are not performing a trade at this time.")
      end
    end

  end
end
