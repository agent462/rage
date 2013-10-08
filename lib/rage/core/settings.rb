require 'fileutils'
require 'mixlib/config'
require 'rainbow'

module Rage
  class Settings

    def is_file?(file)
      !File.readable?(file) ? false : true # rubocop:disable FavorUnlessOverNegatedIf
    end

    def create(directory, file)
      FileUtils.mkdir_p(directory) unless File.directory?(directory)
      FileUtils.cp(File.join(File.dirname(__FILE__), '../../settings.example.rb'), file)
      puts "We created the configuration file for you at #{file}.".color(:red)
      exit
    end

  end

  class Config
    extend(Mixlib::Config)
  end

end
