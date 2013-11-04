module Rage
  class Stats
    attr_reader :time, :all

    AVAILABLE = [:ema, :sma, :trades, :high, :low, :volume, :open, :close]

    def initialize(time)
      @time = time
      @all = Rage.redis.hgetall("mtgox:hour:#{time}")
    end

    AVAILABLE.each do |method|
      define_method(method) do
        all["#{method}"]
      end
    end

    def available
      AVAILABLE
    end

    def empty?
      all.empty? ? true : false
    end

    def message(stat)
      "MtGox #{stat}: #{send(stat)}"
    end

    def method_missing(m, *args, &block)
      "Stat #{m} is not implemented on this class."
    end

  end
end
