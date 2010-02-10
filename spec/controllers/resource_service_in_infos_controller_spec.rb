require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '../app'))

describe "resource_service in InfosController via Account(a user)" do
  controller_name :infos
  
  before(:each) do
    @account    = User.create!
    @info       = Info.create! :user_id => @account.id
    
    @controller.stub!(:current_user).and_return(@account)
    
    get :show, :resource_path => '/account/info'
    @resource_service = controller.send :resource_service
  end
  
  it "should build new interest on the account" do
    resource = @resource_service.new
    resource.should be_kind_of(Info)
    resource.user_id.should == @account.id
  end
  
  it "should find @info with find" do
    resource = @resource_service.find
    resource.should == @info
  end
  
  it "should destroy the info with destroy" do
    lambda { @resource_service.destroy }.should change(Info, :count).by(-1)
    lambda { Info.find(@info.id) }.should raise_error(ActiveRecord::RecordNotFound)
  end
  
  it "should return the destroyed info with destroy" do
    @resource_service.destroy.should == @info
  end
end