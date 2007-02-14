require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))

module InterestsViaUserSpecHelper
  def setup_mocks
    @user = mock('User')
    @user_interests = mock('user_interests assoc')
    User.stub!(:find).and_return(@user)
    @user.stub!(:interests).and_return(@user_interests)
    @user.stub!(:to_param).and_return('1')
  end
end

context "Routing shortcuts for Interests via User (users/1/interests/2) should map" do
  include InterestsViaUserSpecHelper
  controller_name :interests
  
  setup do
    setup_mocks
    @interest = mock('Interest')
    @interest.stub!(:to_param).and_return('2')
    @user_interests.stub!(:find).and_return(@interest)
    
    get :show, :user_id => "1", :id => "2"
  end
  
  specify "resources_path to /users/1/interests" do
    controller.resources_path.should == '/users/1/interests'
  end

  specify "resource_path to /users/1/interests/2" do
    controller.resource_path.should == '/users/1/interests/2'
  end
  
  specify "resource_path(9) to /users/1/interests/9" do
    controller.resource_path(9).should == '/users/1/interests/9'
  end

  specify "edit_resource_path to /users/1/interests/2;edit" do
    controller.edit_resource_path.should == '/users/1/interests/2;edit'
  end
  
  specify "edit_resource_path(9) to /users/1/interests/9;edit" do
    controller.edit_resource_path(9).should == '/users/1/interests/9;edit'
  end
  
  specify "new_resource_path to /users/1/interests/new" do
    controller.new_resource_path.should == '/users/1/interests/new'
  end
end

context "resource_service in InterestsController via Forum" do
  controller_name :interests
  
  setup do
    @user           = User.create
    @interest       = Interest.create :interested_in_id => @user.id, :interested_in_type => 'User'
    @other_user     = User.create
    @other_interest = Interest.create :interested_in_id => @other_user.id, :interested_in_type => 'User'
    
    get :index, :user_id => @user.id
    @resource_service = controller.send :resource_service
  end
  
  specify "should build new interest with @user fk and type with new" do
    resource = @resource_service.new
    resource.should_be_kind_of Interest
    resource.interested_in_id.should == @user.id
    resource.interested_in_type.should == 'User'
  end
  
  specify "should find @interest with find(@interest.id)" do
    resource = @resource_service.find(@interest.id)
    resource.should_be == @interest
  end
  
  specify "should raise RecordNotFound with find(@other_interest.id)" do
    lambda{ @resource_service.find(@other_interest.id) }.should_raise ActiveRecord::RecordNotFound
  end

  specify "should find only interests belonging to @user with find(:all)" do
    resources = @resource_service.find(:all)
    resources.should_be == Interest.find(:all, :conditions => "interested_in_id = #{@user.id} AND interested_in_type = 'User'")
  end
end

context "Requesting /users/1/interests using GET" do
  include InterestsViaUserSpecHelper
  controller_name :interests

  setup do
    setup_mocks
    @interests = mock('Interests')
    @user_interests.stub!(:find).and_return(@interests)
  end
  
  def do_get
    get :index, :user_id => 1
  end

  specify "should find the user" do
    User.should_receive(:find).with('1').and_return(@user)
    do_get
  end

  specify "should assign the found user as :interested_in for the view" do
    do_get
    assigns[:interested_in].should_be @user
  end

  specify "should assign the user_interests association as the interests resource_service" do
    @user.should_receive(:interests).and_return(@user_interests)
    do_get
    @controller.resource_service.should_be @user_interests
  end
end