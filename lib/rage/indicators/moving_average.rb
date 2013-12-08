require 'timerizer'

module Rage
  class MovingAverage

    def self.sma(values)
      count = values.count
      total = values.inject(:+)
      total / count
    end

    def mtgox
      @mtgox ||= MtGox.new
    end

    def self.ema(current_price, periods, previous)
      weight = (2.to_f / (periods.to_i + 1))
      (current_price.to_f * weight) + (previous.to_f * (1 - weight))
    end

    def calculate_periods(periods)
      i, times = 0, []
      while i < periods
        times.push(hour(i.hours.ago))
        i += 1
      end
      times
    end

    def hour(timestamp)
      timestamp.strftime('%Y-%m-%d-%H').gsub(' ', '')
    end

  end
end
