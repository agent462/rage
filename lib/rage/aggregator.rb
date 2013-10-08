require 'redis'

module Rage
  class Aggregator

    def initialize
      @redis = Redis.new(:host => "127.0.0.1", :port => 6379)
      @logger = Rage.logger
    end

    def update_hour(hour)
      trades = @redis.smembers(hour)
      count = trades.count
      volume = 0
      price = []
      high = 0
      low = 1000000
      trades.each do |trade|
        if trade != 'h'
          details = @redis.hvals(trade)
          if details[2].to_f > high
            high = details[2].to_f
          end
          if details[2].to_f < low
            low = details[2].to_f
          end
          volume += details[0].to_f
          price << details[2].to_f
        end
      end
      close_trade = trades.max
      close_price = @redis.hvals(close_trade)
      open_trade = trades.min
      open_price = @redis.hvals(open_trade)
      h = {
        :sma      => MovingAverage::sma(price),
        :trades   => count,
        :high     => high,
        :low      => low,
        :volume   => volume,
        :open     => open_price[2].to_f,
        :close    => close_price[2].to_f
      }
      @redis.hmset('agg' + hour, 'sma', h[:sma], 'trades', h[:trades], 'high', h[:high], 'low', h[:low], 'volume', h[:volume], 'open', h[:open], 'close', h[:close])
    end

    def save_trades(trades)
      @logger.info('Saving trades and calculating hourly aggregates')
      trades.each do |trade|
        hour = key(trade.date)
        @redis.sadd(hour, trade.id)
        @redis.hmset(trade.id, 'amount', trade.amount.to_digits, 'timestamp', trade.date, 'price', trade.price.to_digits)
        update_hour(hour)
      end
    end

    def key(timestamp)
      timestamp.strftime("%Y-%m-%d-%H").gsub(" ", "")
    end

  end
end
