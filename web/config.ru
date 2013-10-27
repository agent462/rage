require 'sinatra/base'
require './init.rb'

map('/') { run Rage::Web }
