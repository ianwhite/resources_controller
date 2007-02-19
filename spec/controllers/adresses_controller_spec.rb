require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))

module AddressesSpecHelper
  def setup_mocks
    @user = mock('User')
    @user_addresses = mock('Assoc: user_addresses')
    @user.stub!(:addresses).and_return(@user_addresses)
    @user.stub!(:to_param).and_return("2")
    
    User.stub!(:find).and_return(@user)
  end
end

context "Routing shortcuts for Addresses (users/2/addresses/1) should map" do
  include AddressesSpecHelper
  controller_name :addresses

  setup do
    setup_mocks
    @address = mock('Address')
    @address.stub!(:to_param).and_return('1')
    @user_addresses.stub!(:find).and_return(@address)
  
    get :show, :user_id => "2", :id => "1"
  end
  
  specify "resources_path to /users/2/addresses" do
    controller.resources_path.should == '/users/2/addresses'
  end

  specify "resource_path to /users/2/addresses/1" do
    controller.resource_path.should == '/users/2/addresses/1'
  end
  
  specify "resource_path(9) to /users/2/addresses/9" do
    controller.resource_path(9).should == '/users/2/addresses/9'
  end

  specify "edit_resource_path to /users/2/addresses/1;edit" do
    controller.edit_resource_path.should == '/users/2/addresses/1;edit'
  end
  
  specify "edit_resource_path(9) to /users/2/addresses/9;edit" do
    controller.edit_resource_path(9).should == '/users/2/addresses/9;edit'
  end
  
  specify "new_resource_path to /users/2/addresses/new" do
    controller.new_resource_path.should == '/users/2/addresses/new'
  end
end

context "resource_service in AddressesController" do
  controller_name :addresses
  
  setup do
    @user          = User.create
    @address       = Address.create :user_id => @user.id
    @other_user    = User.create
    @other_address = Address.create :user_id => @other_user.id
    
    get :index, :user_id => @user.id
    @resource_service = controller.send :resource_service
  end
  
  specify "should build new address with @user foreign key with new" do
    resource = @resource_service.new
    resource.should_be_kind_of Address
    resource.user_id.should == @user.id
  end
  
  specify "should find @address with find(@address.id)" do
    resource = @resource_service.find(@address.id)
    resource.should_be == @address
  end
  
  specify "should raise RecordNotFound with find(@other_address.id)" do
    lambda{ @resource_service.find(@other_address.id) }.should_raise ActiveRecord::RecordNotFound
  end

  specify "should find only addresses belonging to @user with find(:all)" do
    resources = @resource_service.find(:all)
    resources.should_be == Address.find(:all, :conditions => "user_id = #{@user.id}")
  end
end

context "Requesting /users/2/addresses" do
  include AddressesSpecHelper
  controller_name :addresses
  
  setup do
    setup_mocks
    @addresses = mock('Addresses')
    @user_addresses.stub!(:find).and_return(@addresses)
  end
  
  def do_get
    get :index, :user_id => '2'
  end
    
  specify "should find the user" do
    User.should_receive(:find).with('2').and_return(@user)
    do_get
  end
  
  specify "should assign the found user for the view" do
    do_get
    assigns[:user].should_be @user
  end
  
  specify "should assign the user_addresses association as the addresses resource_service" do
    @user.should_receive(:addresses).and_return(@user_addresses)
    do_get
    @controller.resource_service.service.should_be @user_addresses
  end 
end

context "Requesting /users/2/addresses using GET" do
  include AddressesSpecHelper
  controller_name :addresses

  setup do
    setup_mocks
    @addresses = mock('Addresses')
    @user_addresses.stub!(:find).and_return(@addresses)
  end
  
  def do_get
    get :index, :user_id => '2'
  end
  
  specify "should be successful" do
    do_get
    response.should_be_success
  end

  specify "should render index.rhtml" do
    controller.should_render :index
    do_get
  end
  
  specify "should find all addresses" do
    @user_addresses.should_receive(:find).with(:all).and_return(@addresses)
    do_get
  end
  
  specify "should assign the found addresses for the view" do
    do_get
    assigns[:addresses].should_be @addresses
  end
end

context "Requesting /users/2/addresses/1 using GET" do
  include AddressesSpecHelper
  controller_name :addresses

  setup do
    setup_mocks
    @address = mock('a address')
    @user_addresses.stub!(:find).and_return(@address)
  end
  
  def do_get
    get :show, :id => "1", :user_id => "2"
  end

  specify "should be successful" do
    do_get
    response.should_be_success
  end
  
  specify "should render show.rhtml" do
    controller.should_render :show
    do_get
  end
  
  specify "should find the thing requested" do
    @user_addresses.should_receive(:find).with("1").and_return(@address)
    do_get
  end
  
  specify "should assign the found thing for the view" do
    do_get
    assigns[:address].should_be @address
  end
end

context "Requesting /users/2/addresses/new using GET" do
  include AddressesSpecHelper
  controller_name :addresses

  setup do
    setup_mocks
    @address = mock('new Address')
    @user_addresses.stub!(:new).and_return(@address)
  end
  
  def do_get
    get :new, :user_id => "2"
  end

  specify "should be successful" do
    do_get
    response.should_be_success
  end
  
  specify "should render new.rhtml" do
    controller.should_render :new
    do_get
  end
  
  specify "should create an new thing" do
    @user_addresses.should_receive(:new).and_return(@address)
    do_get
  end
  
  specify "should not save the new thing" do
    @address.should_not_receive(:save)
    do_get
  end
  
  specify "should assign the new thing for the view" do
    do_get
    assigns[:address].should_be @address
  end
end

context "Requesting /users/2/addresses/1;edit using GET" do
  include AddressesSpecHelper
  controller_name :addresses

  setup do
    setup_mocks
    @address = mock('Address')
    @user_addresses.stub!(:find).and_return(@address)
  end
 
  def do_get
    get :edit, :id => "1", :user_id => "2"
  end

  specify "should be successful" do
    do_get
    response.should_be_success
  end
  
  specify "should render edit.rhtml" do
    do_get
    controller.should_render :edit
  end
  
  specify "should find the thing requested" do
    @user_addresses.should_receive(:find).with("1").and_return(@address)
    do_get
  end
  
  specify "should assign the found Thing for the view" do
    do_get
    assigns(:address).should_equal @address
  end
end

context "Requesting /users/2/addresses using POST" do
  include AddressesSpecHelper
  controller_name :addresses

  setup do
    setup_mocks
    @address = mock('Address')
    @address.stub!(:save).and_return(true)
    @address.stub!(:to_param).and_return("1")
    @user_addresses.stub!(:new).and_return(@address)
  end
  
  def do_post
    post :create, :address => {:name => 'Address'}, :user_id => "2"
  end
  
  specify "should create a new address" do
    @user_addresses.should_receive(:new).with({'name' => 'Address'}).and_return(@address)
    do_post
  end

  specify "should redirect to the new address" do
    do_post
    response.should_be_redirect
    response.redirect_url.should_eql "http://test.host/users/2/addresses/1"
  end
end

context "Requesting /users/2/addresses/1 using PUT" do
  include AddressesSpecHelper
  controller_name :addresses

  setup do
    setup_mocks
    @address = mock('Address', :null_object => true)
    @address.stub!(:to_param).and_return("1")
    @user_addresses.stub!(:find).and_return(@address)
  end
  
  def do_update
    put :update, :id => "1", :user_id => "2"
  end
  
  specify "should find the address requested" do
    @user_addresses.should_receive(:find).with("1").and_return(@address)
    do_update
  end

  specify "should update the found address" do
    @address.should_receive(:update_attributes)
    do_update
  end

  specify "should assign the found address for the view" do
    do_update
    assigns(:address).should_be @address
  end

  specify "should redirect to the address" do
    do_update
    response.should_be_redirect
    response.redirect_url.should_eql "http://test.host/users/2/addresses/1"
  end
end

context "Requesting /users/2/addresses/1 using DELETE" do
  include AddressesSpecHelper
  controller_name :addresses

  setup do
    setup_mocks
    @address = mock('Address', :null_object => true)
    @user_addresses.stub!(:find).and_return(@address)
  end
  
  def do_delete
    delete :destroy, :id => "1", :user_id => "2"
  end

  specify "should find the address requested" do
    @user_addresses.should_receive(:find).with("1").and_return(@address)
    do_delete
  end
  
  specify "should call destroy on the found thing" do
    @address.should_receive(:destroy)
    do_delete
  end
  
  specify "should redirect to the things list" do
    do_delete
    response.should_be_redirect
    response.redirect_url.should_eql "http://test.host/users/2/addresses"
  end
end