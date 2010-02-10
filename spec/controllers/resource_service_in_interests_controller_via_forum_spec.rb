require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '../app'))

describe "resource_service in InterestsController via Forum" do
  controller_name :interests
  
  before(:each) do
    @forum          = Forum.create
    @interest       = Interest.create :interested_in_id => @forum.id, :interested_in_type => 'Forum'
    @other_forum    = Forum.create
    @other_interest = Interest.create :interested_in_id => @other_forum.id, :interested_in_type => 'Forum'
    
    get :index, :forum_id => @forum.id
    @resource_service = controller.send :resource_service
  end
  
  it "should build new interest with @forum fk and type with new" do
    resource = @resource_service.new
    resource.should be_kind_of(Interest)
    resource.interested_in_id.should == @forum.id
    resource.interested_in_type.should == 'Forum'
  end
  
  it "should find @interest with find(@interest.id)" do
    resource = @resource_service.find(@interest.id)
    resource.should == @interest
  end
  
  it "should raise RecordNotFound with find(@other_interest.id)" do
    lambda{ @resource_service.find(@other_interest.id) }.should raise_error(ActiveRecord::RecordNotFound)
  end

  it "should find only interests belonging to @forum with find(:all)" do
    resources = @resource_service.find(:all)
    resources.should be == Interest.find(:all, :conditions => "interested_in_id = #{@forum.id} AND interested_in_type = 'Forum'")
  end
  
  it "should destroy the interest with destroy(@interest.id)" do
    lambda { @resource_service.destroy(@interest.id) }.should change(Interest, :count).by(-1)
    lambda { Interest.find(@interest.id) }.should raise_error(ActiveRecord::RecordNotFound)
  end
  
  it "should NOT destory the other interest with destroy(@other_interest.id)" do
    lambda { @resource_service.destroy(@other_interest.id) }.should raise_error
    Interest.find(@other_interest.id).should == @other_interest
  end
  
  it "should return the destroyed interest with destroy(@interest.id)" do
    @resource_service.destroy(@interest.id).should == @interest
  end
end