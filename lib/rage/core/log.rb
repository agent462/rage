require 'logger'
require 'fileutils'

module Rage

  def logger
    Rage.logger
  end

  #
  # Sets up logging device
  #
  def self.logger
    dir = File.join(Dir.home, '.rage/log/')
    file = File.join(dir, 'rage.log')
    FileUtils.mkdir_p(dir) unless File.directory?(dir)
    log_file = File.open(file, 'a+')
    @logger || @logger = Logger.new(MultiIO.new(STDOUT, log_file))
    @logger
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
