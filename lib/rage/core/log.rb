require 'logger'
require 'fileutils'

module Rage
  module Logging

    def logger
      Rage::Logging.logger
    end

    #
    # Sets up logging device
    #
    def self.logger
      unless @logger
        dir = File.join(Dir.home, '.rage/log/')
        file = File.join(dir, 'rage.log')
        FileUtils.mkdir_p(dir) unless File.directory?(dir)
        log_file = File.open(file, 'a+')
        STDOUT.sync = true
        log_file.sync = true
      end
      @logger ||= Logger.new(MultiIO.new(STDOUT, log_file))
    end

    def self.set_level(level)
      case level
      when :info
        Rage::Logging.logger.level = Logger::INFO
      when :debug
        Rage::Logging.logger.level = Logger::DEBUG
      when :error
        Rage::Logging.logger.level = Logger::ERROR
      when :warn
        Rage::Logging.logger.level = Logger::WARN
      when :fatal
        Rage::Logging.logger.level = Logger::FATAL
      end
    end

    #
    # Allows multiple targets for logger
    #
    class MultiIO
      def initialize(*targets)
        @targets = targets
      end

      def write(*args)
        @targets.each { |t| t.write(*args) }
      end

      def close
        @targets.each(&:close)
      end
    end
  end
end
