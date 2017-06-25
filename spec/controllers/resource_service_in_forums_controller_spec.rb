require 'spec_helper'

describe ForumsController do
  describe "resource_service in ForumsController" do
  
    before(:each) do
      @forum = Forum.create
    
      get :index
      @resource_service = controller.send :resource_service
    end
  
    it "should build new forum with new" do
      resource = @resource_service.new
      expect(resource).to be_kind_of(Forum)
    end
  
    it "should find @forum with find(@forum.id)" do
      resource = @resource_service.find(@forum.id)
      expect(resource).to eq(@forum)
    end

    it "should find all forums with .all" do
      resources = @resource_service.all
      expect(resources).to eq(Forum.all)
    end
  
    it "should destroy the forum with destroy(@forum.id)" do
      expect { @resource_service.destroy(@forum.id) }.to change(Forum, :count).by(-1)
      expect { Forum.find(@forum.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  
    it "should return the destroyed forum with destroy(@forum.id)" do
      expect(@resource_service.destroy(@forum.id)).to eq(@forum)
    end
  end
end
