require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))

module TagsViaUserAddressSpecHelper
  def setup_mocks
    @user = mock('User')
    User.stub!(:find).and_return(@user)
    @user.stub!(:to_param).and_return('1')
    @user_addresses = mock('user_addresses assoc')
    @user.stub!(:addresses).and_return(@user_addresses)
    
    @address = mock('Address')
    @user_addresses.stub!(:find).and_return(@address)
    @address.stub!(:to_param).and_return('2')
    @address_tags = mock('address_tags assoc')
    @address.stub!(:tags).and_return(@address_tags)
  end
end

context "Routing shortcuts for Tags via User and Address (users/1/addresses/2/tags/3) should map" do
  include TagsViaUserAddressSpecHelper
  controller_name :tags
  
  setup do
    setup_mocks
    @tag = mock('Tag')
    @tag.stub!(:to_param).and_return('3')
    @address_tags.stub!(:find).and_return(@tag)
    
    get :show, :user_id => "1", :address_id => "2", :id => "3"
  end
  
  specify "resources_path to /users/1/addresses/2/tags" do
    controller.resources_path.should == '/users/1/addresses/2/tags'
  end

  specify "resource_path to /users/1/addresses/2/tags/3" do
    controller.resource_path.should == '/users/1/addresses/2/tags/3'
  end
  
  specify "resource_path(9) to /users/1/addresses/2/tags/9" do
    controller.resource_path(9).should == '/users/1/addresses/2/tags/9'
  end

  specify "edit_resource_path to /users/1/addresses/2/tags/3;edit" do
    controller.edit_resource_path.should == '/users/1/addresses/2/tags/3;edit'
  end
  
  specify "edit_resource_path(9) to /users/1/addresses/2/tags/9;edit" do
    controller.edit_resource_path(9).should == '/users/1/addresses/2/tags/9;edit'
  end
  
  specify "new_resource_path to /users/1/addresses/2/tags/new" do
    controller.new_resource_path.should == '/users/1/addresses/2/tags/new'
  end
end

context "resource_service in TagsController via User and Address" do
  controller_name :tags
  
  setup do
    @user       = User.create
    @address        = Address.create :user_id => @user.id
    @tag         = Tag.create :taggable_id => @address.id, :taggable_type => 'Address'
    @other_address  = Address.create :user_id => @user.id
    @other_tag   = Tag.create :taggable_id => @other_address.id, :taggable_type => 'Address'
    
    get :index, :user_id => @user.id, :address_id => @address.id
    @resource_service = controller.send :resource_service
  end
  
  specify "should build new tag with @address fk and type with new" do
    resource = @resource_service.new
    resource.should_be_kind_of Tag
    resource.taggable_id.should == @address.id
    resource.taggable_type.should == 'Address'
  end
  
  specify "should find @tag with find(@tag.id)" do
    resource = @resource_service.find(@tag.id)
    resource.should_be == @tag
  end
  
  specify "should raise RecordNotFound with find(@other_tag.id)" do
    lambda{ @resource_service.find(@other_tag.id) }.should_raise ActiveRecord::RecordNotFound
  end

  specify "should find only tags belonging to @address with find(:all)" do
    resources = @resource_service.find(:all)
    resources.should_be == Tag.find(:all, :conditions => "taggable_id = #{@address.id} AND taggable_type = 'Address'")
  end
end

context "Requesting /users/1/addresses/2/tags using GET" do
  include TagsViaUserAddressSpecHelper
  controller_name :tags

  setup do
    setup_mocks
    @tags = mock('Tags')
    @address_tags.stub!(:find).and_return(@tags)
  end
  
  def do_get
    get :index, :user_id => 1, :address_id => 2
  end

  specify "should find the user" do
    User.should_receive(:find).with('1').and_return(@user)
    do_get
  end
  
  specify "should find the address" do
    @user_addresses.should_receive(:find).with('2').and_return(@address)
    do_get
  end

  specify "should assign the found address as :taggable for the view" do
    do_get
    assigns[:taggable].should_be @address
  end

  specify "should assign the address_tags association as the tags resource_service" do
    @address.should_receive(:tags).and_return(@address_tags)
    do_get
    @controller.resource_service.should_be @address_tags
  end 
end