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
    get :show
    @resource_service = controller.send :resource_service
  end
  
  it ".new should call :new on User" do
    User.should_receive(:new).with(:args => 'args')
    @resource_service.new :args => 'args'
  end
  
  it ".find should call :find_singleton lambda" do
    @controller.should_receive(:lambda_called)
    @controller.stub!(:find_singleton).and_return(lambda{ lambda_called })
    @resource_service.find
  end
end

#describe "Requesting /forums/2/owner using GET" do
#  include OwnerControllerSpecHelper
#  controller_name :owner
#
#  before(:each) do
#    setup_mocks
#  end
#  
#  def do_get
#    get :show, :forum_id => "2"
#  end
#
#  it "should be successful" do
#    do_get
#    response.should be_success
#  end
#  
#  it "should render show.rhtml" do
#    do_get
#    response.should render_template(:show)
#  end
#  
#  it "should find the forum requested" do
#    Forum.should_receive(:find).with("2").and_return(@forum)
#    do_get
#  end
#  
#  it "should assign the found forum for the view" do
#    do_get
#    assigns[:forum].should == @forum
#  end
#  
#  it "should find the owner from forum.owner" do
#    @forum.should_receive(:owner).and_return(@owner)
#    do_get
#  end
#  
#  it "should assign the found owner for the view" do
#    do_get
#    assigns[:owner].should == @owner
#  end
#end
#
#describe "Requesting /forums/2/owner/new using GET" do
#  include OwnerControllerSpecHelper
#  controller_name :owner
#
#  before(:each) do
#    setup_mocks
#    @forum.stub!(:build_owner).and_return(@owner)
#  end
#  
#  def do_get
#    get :new, :forum_id => "2"
#  end
#
#  it "should be successful" do
#    do_get
#    response.should be_success
#  end
#  
#  it "should render new.rhtml" do
#    do_get
#    response.should render_template(:new)
#  end
#  
#  it "should build a new owner" do
#    @forum.should_receive(:build_owner).and_return(@owner)
#    do_get
#  end
#end
#
#describe "Requesting /forums/2/owner/edit using GET" do
#  include OwnerControllerSpecHelper
#  controller_name :owner
#
#  before(:each) do
#    setup_mocks
#  end
#  
#  def do_get
#    get :edit, :forum_id => "2"
#  end
#
#  it "should be successful" do
#    do_get
#    response.should be_success
#  end
#  
#  it "should render edit.rhtml" do
#    do_get
#    response.should render_template(:edit)
#  end
#  
#  it "should find the owner from forum.owner" do
#    @forum.should_receive(:owner).and_return(@owner)
#    do_get
#  end
#end
#
#describe "Requesting /forums/2/owner using POST" do
#  include OwnerControllerSpecHelper
#  controller_name :owner
#
#  before(:each) do
#    setup_mocks
#    @owner.stub!(:save).and_return(true)
#    @owner.stub!(:to_param).and_return("1")
#    @forum.stub!(:build_owner).and_return(@owner)
#  end
#  
#  def do_post
#    post :create, :forum_id => 2, :owner => {:name => 'Fred'}
#  end
#  
#  it "should build a new owner" do
#    @forum.should_receive(:build_owner).with({'name' => 'Fred'}).and_return(@owner)
#    do_post
#  end
#
#  it "should set the flash notice" do
#    do_post
#    flash[:notice].should == "Owner was successfully created."
#  end
#
#  it "should redirect to the new owner" do
#    do_post
#    response.should be_redirect
#    response.redirect_url.should == "http://test.host/forums/2/owner"
#  end
#end
#
#
#describe "Requesting /forums/2/owner using PUT" do
#  include OwnerControllerSpecHelper
#  controller_name :owner
#
#  before(:each) do
#    setup_mocks
#    @owner.stub!(:save).and_return(true)
#    @owner.stub!(:update_attributes).and_return(true)
#  end
#  
#  def do_update
#    put :update, :forum_id => "2", :owner => {:name => 'Fred'}
#  end
#  
#  it "should find the owner from forum.owner" do
#    @forum.should_receive(:owner).and_return(@owner)
#    do_update
#  end
#
#  it "should set the flash notice" do
#    do_update
#    flash[:notice].should == "Owner was successfully updated."
#  end
#
#  it "should update the owner" do
#    @owner.should_receive(:update_attributes).with('name' => 'Fred')
#    do_update
#  end
#
#  it "should redirect to the owner" do
#    do_update
#    response.should redirect_to("http://test.host/forums/2/owner")
#  end
#end
#
#
#describe "Requesting /forums/2/owner using DELETE" do
#  include OwnerControllerSpecHelper
#  controller_name :owner
#
#  before(:each) do
#    setup_mocks
#    @owner.stub!(:destroy).and_return(@owner)
#  end
#  
#  def do_delete
#    delete :destroy, :forum_id => "2"
#  end
#
#  it "should find the owner from forum.owner" do
#    @forum.should_receive(:owner).and_return(@owner)
#    do_delete
#  end
#  
#  it "should call destroy on the owner" do
#    @owner.should_receive(:destroy).and_return(@owner)
#    do_delete
#  end
#  
#  it "should set the flash notice" do
#    do_delete
#    flash[:notice].should == 'Owner was successfully destroyed.'
#  end
#  
#  it "should redirect to forums/2" do
#    do_delete
#    response.should redirect_to("http://test.host/forums/2")
#  end
#end
#
#