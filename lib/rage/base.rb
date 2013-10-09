require 'rage/exchange/mtgox'
require 'pp'

module Rage
  class Base

    def initialize
      @logger = logger
    end

    def setup
      settings
      run
    end

    def logger
      logger = Rage.logger
      logger.level = Logger::INFO
      logger
    end

    def settings
      directory = "#{Dir.home}/.rage"
      file = "#{directory}/settings.rb"
      settings = Settings.new
      if settings.is_file?(file)
        Rage::Config.from_file(file)
      else
        settings.create(directory, file)
      end
    end

    def run
      mtgox = MtGox.new
      account = mtgox.get_balance
      @logger.info('Account information')
      @logger.info("USD: $#{account["USD"]}")
      @logger.info("BTC: #{account["BTC"]}")
      current_price
      Rage::Scheduler.run
    end

    def current_price
      mtgox = MtGox.new
      @logger.info("Current MtGox Price: $#{mtgox.current_price}")
    end

    def handle
      max = Max.new
      d = max.fetch
      @logger.info("The recommendation from Max is to #{max.trade(d)}".color(:cyan))
    end

  end
end
