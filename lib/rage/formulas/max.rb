require 'net/http'
require 'csv'
require 'json'

module Rage
  class Max

    def initialize
      @logger = Rage.logger
    end

    def schedule
      %w[01:25 07:25 13:25 19:25]
    end

    def fetch
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
    def trade(data)
      data.each do |d|
        if d[0] == '1_hour_analysis_last'
          redis = Redis.new(:host => Config.redis_host, :port => Config.redis_port)
          old_value = redis.get('1_hour_max')
          redis.set('1_hour_max', d[2])
          if old_value
            case d[2]
            when "-1"
              if old_value == '1' || old_value == '0'
                return 'sell'
              else
                return 'hold'
              end
            when "0"
              return 'hold'
            when "1"
              if old_value == '-1' || old_value == '0'
                return 'buy'
              else
                return 'hold'
              end
            end
          else
            return 'hold' # when redis doesn't have an old value
          end
        # else
        #   @logger.error('Insufficient data returned from Max.  You might want to check manually.')
        #   return 'hold' # insufficient data
        end
      end
    end

  end
end
