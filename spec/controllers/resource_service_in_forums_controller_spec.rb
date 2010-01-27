require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '../app'))

describe "resource_service in ForumsController" do
  controller_name :forums
  
  before(:each) do
    @forum = Forum.create
    
    get :index
    @resource_service = controller.send :resource_service
  end
  
  it "should build new forum with new" do
    resource = @resource_service.new
    resource.should be_kind_of(Forum)
  end
  
  it "should find @forum with find(@forum.id)" do
    resource = @resource_service.find(@forum.id)
    resource.should == @forum
  end

  it "should find all forums with find(:all)" do
    resources = @resource_service.find(:all)
    resources.should == Forum.find(:all)
  end
  
  it "should destroy the forum with destroy(@forum.id)" do
    lambda { @resource_service.destroy(@forum.id) }.should change(Forum, :count).by(-1)
    lambda { Forum.find(@forum.id) }.should raise_error(ActiveRecord::RecordNotFound)
  end
  
  it "should return the destroyed forum with destroy(@forum.id)" do
    @resource_service.destroy(@forum.id).should == @forum
  end
end