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

        scheduler.every '1m' do

        end

        scheduler.every '10m' do
          agg = Aggregator.new
          agg.prime
        end

        scheduler.every '15m' do
          base.handle
        end

        scheduler.join
      end

    end
  end
end
