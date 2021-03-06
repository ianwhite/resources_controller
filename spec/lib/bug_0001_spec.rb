require 'spec_helper'

module Bug0001Spec
  class Thing < ActiveRecord::Base
  end
  
  class MyController < ActionController::Base
    def respond_to?(method)
      super(method)
    end
    
    resources_controller_for :things, :class => Thing
  end
  
  describe "Calling respond_to? when it has an old signature buried in there [#1]" do
    it "should work just fine" do
      c = MyController.new
      expect(c.respond_to?(:foo)).to eq(false)
    end
  end
end
