require 'redis'

module Rage
  class Aggregator

    def initialize
      @logger = Rage.logger
    end

    def redis
      @redis ||= Redis.new(:host => Config.redis_host, :port => Config.redis_port)
    end

    def mtgox
      @mtgox ||= MtGox.new
    end

    def prime
      # 1382003833373180
      last_trade = get_last_saved_trade(today(Time.now))
      pp last_trade.first
      if last_trade.empty?
        trades = mtgox.get_trades
      else
        trades = mtgox.get_trades(:since => last_trade.first.to_i)
      end
      @logger.info("Fetched #{trades.count} trades.")
      save_trades(trades)
    end

    def get_last_saved_trade(time)
      redis.sort(
                  "mtgox:trades:#{time}",
                  :by => 'nosort',
                  :get => '#',
                  :get => ['*->id', '*->amount', '*->price'],
                  :order => 'desc',
                  :limit => [0, 1]
                ).first
    end

    def update_hour(hour)
      trades = redis.smembers(hour)
      count = trades.count
      volume, price, high, low = 0, [], 0, 1000000
      trades.each do |trade|
        if trade != 'h'
          details = redis.hvals(trade)
          high = details[2].to_f if details[2].to_f > high
          low = details[2].to_f  if details[2].to_f < low
          volume += details[0].to_f
          price << details[2].to_f
        end
      end
      close_price = redis.hvals(trades.max)
      open_price = redis.hvals(trades.min)
      sma = MovingAverage::sma(price)
      redis.hmset('agg:' + hour, 'sma', sma, 'trades', count, 'high', high, 'low', low, 'volume', volume, 'open', open_price[2].to_f, 'close', close_price[2].to_f)
    end

    def save_trades(trades)
      @logger.info('Saving trades and calculating hourly aggregates')
      trades.each do |trade|
        time = Time.now
        hour = key(Time.now)
        redis.zadd("mtgox:trades:#{today(time)}", time.to_i, "mtgox:trade:#{trade.id}")
        redis.hmset("mtgox:trade:#{trade.id}", 'id', trade.id, 'amount', trade.amount.to_digits, 'timestamp', trade.date, 'price', trade.price.to_digits)
        # update_hour(hour)
      end
    end

    def save_current_price(current)
      redis.zadd('mtgox:price', Time.now.to_i, current)
    end

    def get_current_price
      current = mtgox.current_price
      last =  redis.sort(
                  'mtgox:price',
                  :by => 'nosort',
                  :order => 'desc',
                  :limit => [0, 1]
                ).first
      save_current_price(current)
      @logger.info("Current MtGox Price: $#{current} (#{percentage_difference(current, last)}%)")
    end

    def percentage_difference(first, second)
      (((first.to_f / second.to_f) - 1) * 100).round(3)
    end

    def key(timestamp)
      timestamp.strftime('%Y-%m-%d-%H').gsub(' ', '')
    end

    def today(timestamp)
      timestamp.strftime('%Y-%m-%d').gsub(' ', '')
    end

  end
end
