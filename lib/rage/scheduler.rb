require 'rufus-scheduler'
require 'rainbow'

module Rage
  class Scheduler
    class << self
      include Logging

      def run
        scheduler = Rufus::Scheduler.new
        mtgox = MtGox.new
        max = Max.new
        agg = Aggregator.new

        scheduler.every '15m', :first_at => Time.now + 10 do
          account = mtgox.get_balance
          logger.info('Account information'.color(:green))
          logger.info("USD: $#{account["USD"]}".color(:green))
          logger.info("BTC: #{account["BTC"]}".color(:green))
        end

        scheduler.every '5m', :first_at => Time.now + 10 do
          agg.get_current_price
        end

        # scheduler.every '10m', :first_at => Time.now + 10 do
        #   agg = Aggregator.new
        #   agg.prime
        # end

        scheduler.every '15m', :first_at => Time.now + 10 do
          max.collect
          advice = max.get_brain
          logger.info("The recommendation from Max is to #{advice}".color(:cyan))
          dec = Decision.new
          dec.make(advice)
          max.get_brains
        end

        scheduler.join
      end

    end
  end
end
