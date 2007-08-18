require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '../app'))

describe "ResourcesController#resources_request for recognized_route" do
  before do
    @routes = ActionController::Routing::Routes.named_routes
    @controller = ForumsController.new
  end
  
  it ':users should be [{:name => "users"}]' do
    @controller.stub!(:recognized_route).and_return(@routes[:users])
    @controller.send(:resources_request).should == [{:name => 'users'}]
  end

  it ':user should be [{:name => "users", :key => :id}]' do
    @controller.stub!(:recognized_route).and_return(@routes[:user])
    @controller.send(:resources_request).should == [{:name => 'users', :key => :id}]
  end
  
  it ':user_interests should be [{:name => "users", :key => :user_id, :name_prefix => "user_"}, {:name => "interests"}]' do
    @controller.stub!(:recognized_route).and_return(@routes[:user_interests])
    @controller.send(:resources_request).should == [{:name => "users", :key => :user_id, :name_prefix => "user_"}, {:name => "interests"}]
  end

  it ':user_interest should be [{:name => "users", :key => :user_id, :name_prefix => "user_"}, {:name => "interests", :key => :id, :id => "2"}]' do
    @controller.stub!(:recognized_route).and_return(@routes[:user_interest])
    @controller.send(:resources_request).should == [{:name => "users", :key => :user_id, :name_prefix => "user_"}, {:name => "interests", :key => :id}]
  end

  it ':forum_post_tag should be [{:name => "forums", :key => :forum_id, :name_prefix => "forum_"}, {:name => "posts", :key => :post_id, :name_prefix => "post_"}, {:name => "tags", :key => :id}]' do
    @controller.stub!(:recognized_route).and_return(@routes[:forum_post_tag])
    @controller.send(:resources_request).should == [{:name => "forums", :key => :forum_id, :name_prefix => "forum_"}, {:name => "posts", :key => :post_id, :name_prefix => "post_"}, {:name => "tags", :key => :id}]
  end
  
  it ':account should be [{:name => "account"}]' do
    @controller.stub!(:recognized_route).and_return(@routes[:account])
    @controller.send(:resources_request).should == [{:name => "account"}]
  end
  
  it ':account_info should be [{:name => "account", :name_prefix => "account_"}, {:name => "info"}]' do
    @controller.stub!(:recognized_route).and_return(@routes[:account_info])
    @controller.send(:resources_request).should == [{:name => "account", :name_prefix => "account_"}, {:name => "info"}]
  end
  
  it ':account_info_tags should be [{:name => "account", :name_prefix => "account_"}, {:name => "info", :name_prefix => "info_"}, {:name => "tags"}]' do
    @controller.stub!(:recognized_route).and_return(@routes[:account_info_tags])
    @controller.send(:resources_request).should == [{:name => "account", :name_prefix => "account_"}, {:name => "info", :name_prefix => "info_"}, {:name => "tags"}]
  end
  
  it ':account_post should be [{:name => "account", :name_prefix => "account_"}, {:name => "posts", :key => :id}]' do
    @controller.stub!(:recognized_route).and_return(@routes[:account_post])
    @controller.send(:resources_request).should == [{:name => "account", :name_prefix => "account_"}, {:name => "posts", :key => :id}]
  end
  
  it ':forum_owner_post should be [{:name => "forums", :name_prefix => "forum_", :key => :forum_id}, {:name => "owner", :name_prefix => "owner_"}, {:name ="posts", :key => :id}]' do
    @controller.stub!(:recognized_route).and_return(@routes[:forum_owner_post])
    @controller.send(:resources_request).should == [{:name => "forums", :name_prefix => "forum_", :key => :forum_id}, {:name => "owner", :name_prefix => "owner_"}, {:name => "posts", :key => :id}]
  end
end