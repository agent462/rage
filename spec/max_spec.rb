require File.dirname(__FILE__) + '/../lib/rage/core/log.rb'
require File.dirname(__FILE__) + '/../lib/rage/formulas/max.rb'

describe 'Rage::Max' do

  before do
    @max = Rage::Max.new
  end

  describe 'recommendations' do
    it 'can return a proper buy' do
      values = [[0, '1'], [0, '-1']]
      output = @max.recommendation(values)
      output.should == { :current => 'buy', :previous => 'sell', :signal => 'positive', :advice => 'buy' }
    end

    it 'can return a proper sell' do
      values = [[0, '-1'], [0, '1']]
      output = @max.recommendation(values)
      output.should == { :current => 'sell', :previous => 'buy', :signal => 'negative', :advice => 'sell' }
    end

    it 'can return a proper hold (sell)' do
      values = [[0, '-1'], [0, '-1']]
      output = @max.recommendation(values)
      output.should == { :current => 'sell', :previous => 'sell', :signal => 'negative', :advice => 'hold' }
    end

    it 'can return a proper hold (buy)' do
      values = [[0, '1'], [0, '1']]
      output = @max.recommendation(values)
      output.should == { :current => 'buy', :previous => 'buy', :signal => 'positive', :advice => 'hold' }
    end

    it 'can return a proper hold (unsure)' do
      values = [[0, '0'], [0, '0']]
      output = @max.recommendation(values)
      output.should == { :current => 'hold', :previous => 'hold', :signal => 'unsure', :advice => 'hold' }
    end

    it 'can return a proper hold (sell -> unsure)' do
      values = [[0, '0'], [0, '-1']]
      output = @max.recommendation(values)
      output.should == { :current => 'hold', :previous => 'sell', :signal => 'unsure', :advice => 'hold' }
    end

    it 'can return a proper hold (buy -> unsure)' do
      values = [[0, '0'], [0, '1']]
      output = @max.recommendation(values)
      output.should == { :current => 'hold', :previous => 'buy', :signal => 'unsure', :advice => 'hold' }
    end

    it 'can return a proper hold (unsure -> buy)' do
      values = [[0, '1'], [0, '0']]
      output = @max.recommendation(values)
      output.should == { :current => 'buy', :previous => 'hold', :signal => 'positive', :advice => 'buy' }
    end

    it 'can return a proper hold (unsure -> sell)' do
      values = [[0, '-1'], [0, '0']]
      output = @max.recommendation(values)
      output.should == { :current => 'sell', :previous => 'hold', :signal => 'negative', :advice => 'sell' }
    end
  end

end
