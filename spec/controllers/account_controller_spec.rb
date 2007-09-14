require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '../app'))

module AccountControllerSpecHelper
  def setup_mocks
    @current_user = mock('user')
    @current_user.stub!(:id).and_return('1')
    User.stub!(:find).and_return(@current_user)
    @controller.instance_variable_set('@current_user', @current_user)
  end
end

describe "Routing shortcuts for Account should map" do
  include AccountControllerSpecHelper
  controller_name :account
  
  before(:each) do
    setup_mocks
    @controller.stub!(:recognized_route).and_return(ActionController::Routing::Routes.named_routes[:account])
    get :show
  end

  it "resource_path to /account" do
    controller.resource_path.should == '/account'
  end
   
  it "resource_info_tags_path to /account/info/tags" do
    controller.resource_info_tags_path.should == "/account/info/tags"
  end
end

describe AccountController, "#resource_service" do
  include AccountControllerSpecHelper
  controller_name :account
  
  before(:each) do
    setup_mocks 
    @controller.stub!(:recognized_route).and_return(ActionController::Routing::Routes.named_routes[:account])
    get :show
    @resource_service = controller.send :resource_service
  end
  
  it ".new should call :new on User" do
    User.should_receive(:new).with(:args => 'args')
    @resource_service.new :args => 'args'
  end
  
  it ".find should call :current_user" do
    @controller.should_receive(:current_user).once.and_return(@current_user)
    @resource_service.find
  end
  
  it ".find should call whatever is in resource_specification @find" do
    @controller.should_receive(:lambda_called).once.and_return(@current_user)
    @controller.send(:resource_specification).instance_variable_set "@find", lambda { lambda_called }
    @resource_service.find
  end
end