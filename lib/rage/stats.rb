module Rage
  class Stats
    attr_reader :time, :hour

    AVAILABLE = [:ema, :sma, :trades, :high, :low, :volume, :open, :close]

    def initialize(time)
      @time = time
      @hour = Rage.redis.hgetall("mtgox:hour:#{time}")
    end

    AVAILABLE.each do |method|
      define_method(method) do
        hour["#{method}"]
      end
    end

    def available
      AVAILABLE
    end

    def empty?
      hour.empty? ? true : false
    end

    def message(stat)
      "MtGox #{stat}: #{send(stat)}"
    end

    def method_missing(m, *args, &block)
      "Stat #{m} is not implemented on this class."
    end

  end
end
