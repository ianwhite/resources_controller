require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '../app'))

describe "ResourcesController#resources_request (route_name:tag, :singleton:false)" do
  before do
    @routes = ActionController::Routing::Routes.named_routes
    @controller = TagsController.new
    @controller.stub!(:route_name).and_return('tag')
    @controller.stub!(:singleton).and_return(false)
  end
  
  it ':tags should be []' do
    @controller.stub!(:recognized_route).and_return(@routes[:tags])
    @controller.send(:resources_request).should == []
  end

  it ':new_tag should be []' do
    @controller.stub!(:recognized_route).and_return(@routes[:new_tag])
    @controller.send(:resources_request).should == []
  end

  it ':edit_tag should be []' do
    @controller.stub!(:recognized_route).and_return(@routes[:edit_tag])
    @controller.send(:resources_request).should == []
  end

  it ':tag should be []' do
    @controller.stub!(:recognized_route).and_return(@routes[:tag])
    @controller.send(:resources_request).should == []
  end

  it ':forum_tags should be [{:name => "forums", :name_prefix => "forum_", :key => :forum_id}]' do
    @controller.stub!(:recognized_route).and_return(@routes[:forum_tags])
    @controller.send(:resources_request).should == [{:name => "forums", :name_prefix => "forum_", :key => :forum_id}]
  end

  it ':forum_tag should be [{:name => "forums", :name_prefix => "forum_", :key => :forum_id}]' do
    @controller.stub!(:recognized_route).and_return(@routes[:forum_tag])
    @controller.send(:resources_request).should == [{:name => "forums", :name_prefix => "forum_", :key => :forum_id}]
  end
  
  it ':user_addresses_tags should be [{:name => "users", :key => :user_id, :name_prefix => "user_"}, {:name => "addresses", :name_prefix => "address_", :key => :address_id}]' do
    @controller.stub!(:recognized_route).and_return(@routes[:user_address_tags])
    @controller.send(:resources_request).should == [{:name => "users", :key => :user_id, :name_prefix => "user_"}, {:name => "addresses", :name_prefix => "address_", :key => :address_id}]
  end

  it ':account_info_tags should be [{:name => "account", :name_prefix => "account_"}, {:name => "info", :name_prefix => "info_"}]' do
    @controller.stub!(:recognized_route).and_return(@routes[:account_info_tags])
    @controller.send(:resources_request).should == [{:name => "account", :name_prefix => "account_"}, {:name => "info", :name_prefix => "info_"}]
  end
  
  it ':new_account_info_tag should be [{:name => "account", :name_prefix => "account_"}, {:name => "info", :name_prefix => "info_"}]' do
    @controller.stub!(:recognized_route).and_return(@routes[:new_account_info_tag])
    @controller.send(:resources_request).should == [{:name => "account", :name_prefix => "account_"}, {:name => "info", :name_prefix => "info_"}]
  end
end