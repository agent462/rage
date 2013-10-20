require 'net/http'
require 'csv'

module Rage
  class Max
    include Logging

    def brains
      @brains ||= %w[ 1_hour_analysis_last 3_hour_analysis_last 6_hour_analysis_last 12_hour_analysis_last 24_hour_analysis_last ]
    end

    def fetch
      logger.info('Fetching data from Max.')
      uri = URI(Config.max_uri)
      CSV.parse(Net::HTTP.get(uri))
    rescue StandardError
      logger.error('There was an error getting the data from Max.'.color(:red))
    end

    #  Redis Set max:3_hour_analysis_last id
    #  Redis Hash max:3_hour_analysis_last:id
    def collect
      data = fetch
      brains.each do |brain|
        data.each do |d|
          if d.include? brain
            logger.info("Saving #{d.first} brain.")
            time = now
            Rage.redis.zadd("max:#{d.first}", time, "max:#{brain}:#{time}")
            Rage.redis.hmset("max:#{brain}:#{time}", 'timestamp', time, 'fitness', d[1], 'signal', d[2], 'last_data', d[3])
          end
        end
      end
    end

    def get_brains
      brains.each do |brain|
        logger.info("The #{brain} advice is to #{get_brain(brain)}")
      end
    end

    def now
      Time.now.to_i
    end

    def get_brain(brain = Config.max_brain)
      values = get_values(brain)
      response(values)
    end

    def response(values)
      if enough_data?(values) && values.count > 1
        if signal_change?(values)
          return recommendation(values[0][1], values[1][1])
        else
          return 'hold'
        end
      else
        logger.error('Not enough data returned from Max to make a decision.'.color(:red))
        return 'hold'
      end
    end

    def get_values(brain)
      Rage.redis.sort(
                  "max:#{brain}",
                  :by => 'nosort',
                  :get => '#',
                  :get => ['*->timestamp', '*->signal'],
                  :order => 'desc',
                  :limit => [0, 2]
                )
    end

    def recommendation(current, previous)
      return 'buy' if current.to_i > previous.to_i && current != '0'
      return 'sell' if current.to_i < previous.to_i && current != '0'
      'hold'
    end

    def enough_data?(values)
      max = values.max_by { |x| x }
      min = values.min_by { |x| x }
      ((max[0].to_i - min[0].to_i) < 1200) && (now - max[0].to_i) < 1200 ? true : false
    end

    def signal_change?(values)
      values[0][1] == values[1][1] ? true : false
    end

  end
end
