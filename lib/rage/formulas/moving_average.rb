module Rage
  class MovingAverage
    class << self

      def sma(values)
        count = values.count
        total = values.inject(:+)
        total / count
      end

      def ema(sma)
        sma = ''
        weight = (2 / (markers + 1))
        ema = (close - EMA(previous)) * weight + EMA(previous)
      end

    end
  end
end
