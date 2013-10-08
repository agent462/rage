require 'rage/exchange/mtgox'
require 'pp'
require 'rufus-scheduler'

module Rage
  class Base

    def setup
      @logger = logger
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
      balance

      scheduler = Rufus::Scheduler.new
      scheduler.every '5m' do
        balance
      end
      scheduler.cron '8 23 * * *' do
        handle
      end
      scheduler.cron '20 1 * * *' do
        handle
      end
      scheduler.cron '20 7 * * *' do
        handle
      end
      scheduler.cron '20 13 * * *' do
        handle
      end
      scheduler.cron '20 19 * * *' do
        handle
      end
      scheduler.join
    end

    def balance
      mtgox = MtGox.new
      @logger.info("Current MtGox Price: $#{mtgox.current_price}")
    end

    def handle
      test = Max.new
      d = test.fetch
      pp test.trade(d)
    end

  end
end
