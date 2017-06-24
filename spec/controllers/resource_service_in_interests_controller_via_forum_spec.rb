require 'spec_helper'

describe InterestsController do
  describe "resource_service in InterestsController via Forum" do
  
    before(:each) do
      @forum          = Forum.create
      @interest       = Interest.create :interested_in_id => @forum.id, :interested_in_type => 'Forum'
      @other_forum    = Forum.create
      @other_interest = Interest.create :interested_in_id => @other_forum.id, :interested_in_type => 'Forum'
    
      get :index, params: { :forum_id => @forum.id }
      @resource_service = controller.send :resource_service
    end
  
    it "should build new interest with @forum fk and type with new" do
      resource = @resource_service.new
      expect(resource).to be_kind_of(Interest)
      expect(resource.interested_in_id).to eq(@forum.id)
      expect(resource.interested_in_type).to eq('Forum')
    end
  
    it "should find @interest with find(@interest.id)" do
      resource = @resource_service.find(@interest.id)
      expect(resource).to eq(@interest)
    end
  
    it "should raise RecordNotFound with find(@other_interest.id)" do
      expect{ @resource_service.find(@other_interest.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "should find only interests belonging to @forum with .all" do
      resources = @resource_service.all
      expect(resources).to eq(Interest.where(interested_in_id: @forum.id, interested_in_type: 'Forum').all)
    end
  
    it "should destroy the interest with destroy(@interest.id)" do
      expect { @resource_service.destroy(@interest.id) }.to change(Interest, :count).by(-1)
      expect { Interest.find(@interest.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  
    it "should NOT destory the other interest with destroy(@other_interest.id)" do
      expect { @resource_service.destroy(@other_interest.id) }.to raise_error(ActiveRecord::RecordNotFound)
      expect(Interest.find(@other_interest.id)).to eq(@other_interest)
    end
  
    it "should return the destroyed interest with destroy(@interest.id)" do
      expect(@resource_service.destroy(@interest.id)).to eq(@interest)
    end
  end
end
