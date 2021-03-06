module Rage
  class Aggregator
    include Logging

    def mtgox
      @mtgox ||= MtGox.new
    end

    def prime
      last_trade = get_last_saved_trade
      trades = last_trade ? mtgox.trades(:since => last_trade.to_i) : mtgox.trades
      logger.debug("Fetched #{trades.count} trades.")
      save_trades(trades) if trades.count > 0
    end

    def get_last_saved_trade
      Rage.redis.get('mtgox:last_saved_trade')
    end

    def update_hour(hours_to_update)
      hours_to_update.each do |h|
        volume, prices, high, low = 0, [], 0, 1000000
        trades = Rage.redis.zrevrange("mtgox:trades:#{h}", 0, -1)
        count = trades.count
        trades.each do |trade|
          details = Rage.redis.hvals(trade)
          high = details[3].to_f if details[3].to_f > high
          low = details[3].to_f  if details[3].to_f < low
          volume += details[1].to_f
          prices << details[3].to_f
        end
        close_price = Rage.redis.hvals(trades.max)
        open_price = Rage.redis.hvals(trades.min)
        sma = MovingAverage::sma(prices)
        Rage.redis.hmset('mtgox:hour:' + h, 'sma', sma, 'trades', count, 'high', high, 'low', low, 'volume', volume, 'open', open_price[3].to_f, 'close', close_price[3].to_f)
      end
    end

    def ema
        stats = Stats.new(hour(Time.now - 3600))
        previous = stats.ema ? stats.ema : stats.sma
        puts short_ema = MovingAverage::ema(mtgox.current_price, Config.ema_short, previous)
        puts long_ema = MovingAverage::ema(mtgox.current_price, Config.ema_long, previous)
        puts long_ema - short_ema
    end

    def save_trades(trades)
      logger.debug('Saving trades and calculating hourly aggregates')
      Rage.redis.set('mtgox:last_saved_trade', trades.max_by { |x| x.id }.id)
      hours_to_update = Set.new
      trades.each do |trade|
        time = Time.now
        Rage.redis.zadd("mtgox:trades:#{hour(micro_to_datetime(trade.id))}", time.to_i, "mtgox:trade:#{trade.id}")
        Rage.redis.hmset("mtgox:trade:#{trade.id}", 'id', trade.id, 'amount', trade.amount.to_digits, 'timestamp', trade.date, 'price', trade.price.to_digits)
        hours_to_update.add(hour(micro_to_datetime(trade.id)))
      end
      update_hour(hours_to_update)
    end

    def save_current_price(current)
      Rage.redis.zadd('mtgox:price', Time.now.to_i, current)
    end

    def get_current_price
      current = mtgox.current_price
      last =  Rage.redis.sort(
                  'mtgox:price',
                  :by => 'nosort',
                  :order => 'desc',
                  :limit => [0, 1]
                ).first
      save_current_price(current)
      logger.info("Current MtGox Price: $#{current} (#{percentage_difference(current, last)}%)".color(:cyan))
    end

    def get_hour_info
      stat = Stats.new(hour(Time.now))
      if stat.empty?
        logger.info('No hourly aggregated data available')
      else
        logger.info('===== Data for this Hour ====='.color(:cyan))
        stat.available.each do |item|
          logger.info(stat.message(item).color(:cyan))
        end
      end
    end

    def percentage_difference(first, second)
      (((first.to_f / second.to_f) - 1) * 100).round(3)
    end

    def hour(timestamp)
      timestamp.strftime('%Y-%m-%d-%H').gsub(' ', '')
    end

    def micro_to_datetime(micro)
      Time.at(micro / 1000000)
    end

  end
end
