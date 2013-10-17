require 'net/http'
require 'csv'

module Rage
  class Max

    def initialize
      @logger = Rage.logger
    end

    def redis
      @redis ||= Redis.new(:host => Config.redis_host, :port => Config.redis_port)
    end

    def brains
      @brains ||= %w[ 1_hour_analysis_last 3_hour_analysis_last 6_hour_analysis_last 12_hour_analysis_last 24_hour_analysis_last ]
    end

    def fetch
      @logger.info('Fetching data from Max.')
      uri = URI(Config.max_uri)
      CSV.parse(Net::HTTP.get(uri))
    rescue StandardError
      @logger.error('There was an error getting the data from Max.')
    end

    #
    #  Will return action to do
    #  Buy: buy btc if we are holding cash
    #  Sell: sell btc if we are holding btc
    #  Hold: don't take any action
    #
    #  Redis Set max:3_hour_analysis_last id
    #  Redis Hash max:3_hour_analysis_last:id
    def collect
      data = fetch
      brains.each do |brain|
        data.each do |d|
          if d.include? brain
            @logger.info("Saving #{d[0]} brain.")
            time = Time.now.to_i
            redis.zadd("max:#{d[0]}", time, "max:#{brain}:#{time}")
            redis.hmset("max:#{brain}:#{time}", 'timestamp', time, 'fitness', d[1], 'signal', d[2], 'last_data', d[3])
          end
        end
      end
      get_brains
    end

    def get_brains
      brains.each do |brain|
        values = get_values(brain)
        response(values)
      end
    end

    def get_brain(brain = Config.max_brain)
      values = get_values(brain)
      response(values)
    end

    def response(values)
      if enough_data?(values)
        if signal_change?(values)
          puts recommendation(values[0][1], values[1][1])
        else
          puts 'hold'
        end
      else
        @logger.error('Not enough data')
      end
    end

    def get_values(brain)
      redis.sort(
                  "max:#{brain}",
                  :by => 'nosort',
                  :get => '#',
                  :get => ['*->timestamp', '*->signal'],
                  :order => 'desc',
                  :limit => [0,2]
                )
    end

    def recommendation(current, previous)
      return 'buy' if current.to_i > previous.to_i && current != '0'
      return 'sell' if current.to_i < previous.to_i && current != '0'
      return 'hold'
    end

    def enough_data?(values)
      max = values.max_by { |x| x}
      min = values.min_by { |x| x}
      (max[0].to_i - min[0].to_i) < 1200 ? true : false
    end

    def signal_change?(values)
      values[0][1] == values[1][1] ? true : false
    end

  end
end

