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

    #  Redis Sorted Set max:3_hour_analysis_last id
    #  Redis Hash max:3_hour_analysis_last:id
    def collect
      data = fetch
      brains.each do |brain|
        data.each do |d|
          if d.include? brain
            logger.debug("Saving #{d.first} brain.")
            time = now
            Rage.redis.zadd("max:#{d.first}", time, "max:#{brain}:#{time}")
            Rage.redis.hmset("max:#{brain}:#{time}", 'timestamp', time, 'fitness', d[1], 'signal', d[2], 'last_data', d[3])
          end
        end
      end
    end

    def display_brains
      brains.each do |brain|
        advice = advice(brain)
        logger.info("The #{brain} advice is to #{advice[:advice]} with a #{advice[:signal]} outlook")
      end
    end

    def now
      Time.now.to_i
    end

    def advice(brain = Config.max_brain)
      values = get_values(brain)
      response(values)
    end

    def response(values)
      if enough_data?(values) && values.count > 1
        return recommendation(values)
      else
        logger.error('Not enough data returned from Max to make a decision.'.color(:red))
        return { :advice => 'hold', :current => signal_mapper(values[0][1]), :previous => nil, :signal => signal_outlook(values[0][1]) }
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

    def recommendation(values)
      current, previous = values[0][1], values[1][1]
      h = { :current => signal_mapper(current), :previous => signal_mapper(previous), :signal => signal_outlook(current) }
      return h.merge!(:advice => 'hold') if signal_change?(values) == false
      return h.merge!(:advice => 'buy') if current.to_i > previous.to_i && current.to_i != 0
      return h.merge!(:advice => 'sell') if current.to_i < previous.to_i && current.to_i != 0
      h.merge!(:advice => 'hold')
    end

    def signal_mapper(signal)
      return 'buy' if signal == '1'
      return 'sell' if signal == '-1'
      return 'hold' if signal == '0'
    end

    def signal_outlook(signal)
      return 'positive' if signal == '1'
      return 'negative' if signal == '-1'
      return 'unsure' if signal == '0'
    end

    def enough_data?(values)
      max = values.max_by { |x| x }
      min = values.min_by { |x| x }
      ((max[0].to_i - min[0].to_i) < 1200) && (now - max[0].to_i) < 1200 ? true : false
    end

    def signal_change?(values)
      values[0][1] == values[1][1] ? false : true
    end

  end
end
