require 'rage/exchange/mtgox'

module Rage
  class Base
    include Logging

    def settings
      directory = "#{Dir.home}/.rage"
      file = "#{directory}/settings.rb"
      settings = Settings.new
      settings.is_file?(file) ? Rage::Config.from_file(file) : settings.create(directory, file)
    end

    def run
      settings
      logger.info('Scheduling jobs to run.')
      Rage::Scheduler.run
    end

  end
end
