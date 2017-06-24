require 'spec_helper'

module IncludeActionsSpec
  module Actions
    def foo; end
    def bar; end
    def faz; end
  end

  class ActionsController < ActionController::Base
    include_actions Actions
  end
  
  class OnlyFooController < ActionController::Base
    include_actions Actions, :only => :foo
  end
  
  class ExceptFooBarController < ActionController::Base
    include_actions Actions, :except => [:foo, :bar]
  end

  describe "Include actions use case" do
    it "ActionController should have actions from actions module" do
      expect(ActionsController.action_methods).to eq(['foo', 'bar', 'faz'].to_set)
    end
    
    it "OnlyFooController should have only :foo from actions module" do
      expect(OnlyFooController.action_methods).to eq(['foo'].to_set)
    end
    
    it "ExceptFooBarController should not have :foo, :bar from actions module" do
      expect(ExceptFooBarController.action_methods).to eq(['faz'].to_set)
    end
  end
end
