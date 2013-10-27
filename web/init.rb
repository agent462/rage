require File.dirname(__FILE__) + '/lib/trades'
require 'sinatra'
require 'sinatra/reloader'

module Rage
  class Web < Sinatra::Base

    configure :development do
      register Sinatra::Reloader
      set :start_time, Time.now
    end

    get '/' do
      @title = 'Rage Trader'
      t = Rage::WebStack::Trades.new
      @trades = t.get_trades
      erb :home
    end

    not_found do
      erb :not_found
    end

    def css(*stylesheets)
      stylesheets.map do |stylesheet|
        "<link href=\"css/#{stylesheet}.css\" media=\"screen, projection\" rel=\"stylesheet\" />"
      end.join
    end

  def current?(path = '/')
    (request.path == path || request.path == path + '/') ? "active" : nil
  end

  end
end
