require 'rufus-scheduler'

module Rage
  class Scheduler
    class << self

      def run
        scheduler = Rufus::Scheduler.new
        base = Base.new

        scheduler.every '5m' do
          base.current_price
        end

        scheduler.every '10m' do
          agg = Aggregator.new
          agg.prime
        end

        scheduler.every '15m' do
          base.handle
        end


        # scheduler.cron '20 1 * * *' do
        #   handle
        # end

        # scheduler.cron '01 9 * * *' do
        #   handle
        # end

        # scheduler.cron '20 13 * * *' do
        #   handle
        # end

        # scheduler.cron '20 19 * * *' do
        #   handle
        # end

        scheduler.join
      end

    end
  end
end
