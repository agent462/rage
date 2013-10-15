require 'rufus-scheduler'

module Rage
  class Scheduler
    class << self

      def run
        scheduler = Rufus::Scheduler.new
        base = Base.new
        @logger = base.logger

        scheduler.every '15m', :firat_at => Time.now + 10 do
          mtgox = MtGox.new
          account = mtgox.get_balance
          @logger.info('Account information')
          @logger.info("USD: $#{account["USD"]}")
          @logger.info("BTC: #{account["BTC"]}")
        end

        scheduler.every '5m', :first_at => Time.now + 10 do
          Scheduler.current_price
        end

        scheduler.every '10m', :first_at => Time.now + 10 do
          agg = Aggregator.new
          agg.prime
        end

        scheduler.every '15m', :first_at => Time.now + 10 do
          Scheduler.handle
        end

        scheduler.join
      end

      def current_price
        mtgox = MtGox.new
        @logger.info("Current MtGox Price: $#{mtgox.current_price}")
      end

      def handle
        max = Max.new
        d = max.fetch
        @logger.info("The recommendation from Max is to #{max.trade(d)}".color(:cyan))
      end

    end
  end
end
