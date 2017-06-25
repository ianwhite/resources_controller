require 'spec_helper'

describe CommentsController, "#resource_saved" do
  describe "Comment.new(<invalid attrs>)" do
    before { @controller.resource = Comment.new }
    
    it { expect(@controller).not_to be_resource_saved }
  
    describe ".save" do
      before { @controller.resource.save }

      it { expect(@controller).not_to be_resource_saved }

      describe "then update(<valid attrs>)" do
        before { @controller.resource.update :user => User.create!, :post => Post.create! }
        
        it { expect(@controller).to be_resource_saved }
      end
    end
  end
    
  describe "Comment.find(<id>)" do
    before do
      Comment.create! :user => User.create!, :post => Post.create!
      @controller.resource = Comment.first
    end
    
    it { expect(@controller).to be_resource_saved }

    it ".save should be saved" do
      @controller.resource.save
      expect(@controller).to be_resource_saved
    end

    describe "then update(<invalid attrs>)" do
      before { @controller.resource.update :user => nil }
      
      it { expect(@controller).not_to be_resource_saved }
    end
    
    describe "then update(<new valid attrs>)" do
      before { @controller.resource.update :user => User.create! }
      
      it { expect(@controller).to be_resource_saved }
    end
  end
end
