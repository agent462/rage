require 'redis'

module Rage
  class Aggregator

    def initialize
      @redis = Redis.new(:host => Config.redis_host, :port => Config.redis_port)
      @logger = Rage.logger
    end

    def prime
      mtgox = MtGox.new
      trades = mtgox.get_trades(:since => get_last_saved_trade.to_i)
      @logger.info("Fetched #{trades.count} trades.")
      save_trades(trades)
    end

    def get_last_saved_trade
      @redis.smembers(key(Time.now)).max # need to get last hour
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
          high = details[2].to_f if details[2].to_f > high
          low = details[2].to_f  if details[2].to_f < low
          volume += details[0].to_f
          price << details[2].to_f
        end
      end
      close_price = @redis.hvals(trades.max)
      open_price = @redis.hvals(trades.min)
      sma = MovingAverage::sma(price)
      @redis.hmset('agg:' + hour, 'sma', sma, 'trades', count, 'high', high, 'low', low, 'volume', volume, 'open', open_price[2].to_f, 'close', close_price[2].to_f)
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
