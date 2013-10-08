require 'net/http'
require 'csv'
require 'json'

module Rage
  class Max

    def schedule
      %w[01:25 07:25 13:25 19:25]
    end

    def fetch
      uri = URI('')
      CSV.parse(Net::HTTP.get(uri))
    end

    def trade(data)
      data.each do |d|
        if d[0] == '6_hour_analysis_last'
          redis = Redis.new(:host => "127.0.0.1", :port => 6379)
          old_value = redis.get('6_hour_max')
          redis.set('6_hour_max', d[2])
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
            return 'hold'
          end
        end
      end
    end

  end
end
