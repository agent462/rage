module Rage
  class Stats
    attr_accessor :time, :hour

    def initialize(time)
      @time = time
      @hour = Rage.redis.hgetall("mtgox:hour:#{@time}")
    end

    [:ema, :sma, :trades, :high, :low, :volume, :open, :close].each do |method|
      define_method(method) do
        hour["#{method}"]
      end
    end

    def empty?
      hour.empty? ? true : false
    end

    def message(stat)
      "MtGox #{stat}: #{self.send(stat)}"
    end

    def method_missing(m, *args, &block)
      "Stat #{m} is not implemented on this class."
    end

  end
end
