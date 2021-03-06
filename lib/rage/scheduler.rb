require 'rufus-scheduler'
require 'rainbow'

module Rage
  class Scheduler
    class << self
      include Logging

      def run
        scheduler = Rufus::Scheduler.new
        mtgox = MtGox.new
        agg = Aggregator.new
        indicator = Rage::const_get(Config.trader).new

        scheduler.every '15m', :first_at => Time.now + 2 do
          account = mtgox.get_balance
          logger.info('Account information'.color(:green))
          logger.info("USD: $#{account["USD"]}".color(:green))
          logger.info("BTC: #{account["BTC"]}".color(:green))
        end

        scheduler.every '5m', :first_at => Time.now + 2 do
          agg.get_current_price
        end

        scheduler.every '5m', :first_at => Time.now + 2 do
          agg = Aggregator.new
          agg.prime
          agg.get_hour_info
        end

        scheduler.every '10m', :first_at => Time.now + 2 do
          indicator.collect
          advice = indicator.advice
          logger.info("The recommendation from Max is to #{advice[:advice]} and has a #{advice[:signal]} outlook.".color(:cyan))
          dec = Decision.new(mtgox)
          dec.make(advice)
          indicator.display_brains
        end

        scheduler.join
      end

    end
  end
end
