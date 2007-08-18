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

  it ':user should be [{:name => "users", :id => "1", :key => :id}]' do
    @controller.stub!(:params).and_return(:id => "1")
    @controller.stub!(:recognized_route).and_return(@routes[:user])
    @controller.send(:resources_request).should == [{:name => 'users', :id => "1", :key => :id}]
  end
  
  it ':user_interests should be [{:name => "users", :id => "1", :key => :user_id, :name_prefix => "user_"}, {:name => "interests"}]' do
    @controller.stub!(:params).and_return(:user_id => "1")
    @controller.stub!(:recognized_route).and_return(@routes[:user_interests])
    @controller.send(:resources_request).should == [{:name => "users", :id => "1", :key => :user_id, :name_prefix => "user_"}, {:name => "interests"}]
  end

  it ':user_interest should be [{:name => "users", :id => "1", :key => :user_id, :name_prefix => "user_"}, {:name => "interests", :key => :id, :id => "2"}]' do
    @controller.stub!(:params).and_return(:user_id => "1", :id => "2")
    @controller.stub!(:recognized_route).and_return(@routes[:user_interest])
    @controller.send(:resources_request).should == [{:name => "users", :id => "1", :key => :user_id, :name_prefix => "user_"}, {:name => "interests", :key => :id, :id => "2"}]
  end

  it ':forum_post_tag should be [{:name => "forums", :id => "1", :key => :forum_id, :name_prefix => "forum_"}, {:name => "posts", :key => :post_id, :id => "2", :name_prefix => "post_"}, {:name => "tags", :id => "3", :key => :id}]' do
    @controller.stub!(:params).and_return(:forum_id => "1", :post_id => "2", :id => "3")
    @controller.stub!(:recognized_route).and_return(@routes[:forum_post_tag])
    @controller.send(:resources_request).should == [{:name => "forums", :id => "1", :key => :forum_id, :name_prefix => "forum_"}, {:name => "posts", :key => :post_id, :id => "2", :name_prefix => "post_"}, {:name => "tags", :id => "3", :key => :id}]
  end
  
  it ':my_home should be [{:name => "my_home"}]' do
    @controller.stub!(:recognized_route).and_return(@routes[:my_home])
    @controller.send(:resources_request).should == [{:name => "my_home"}]
  end
  
  it ':my_home_info should be [{:name => "my_home", :name_prefix => "my_home_"}, {:name => "info"}]' do
    @controller.stub!(:recognized_route).and_return(@routes[:my_home_info])
    @controller.send(:resources_request).should == [{:name => "my_home", :name_prefix => "my_home_"}, {:name => "info"}]
  end
  
  it ':my_home_info_tags should be [{:name => "my_home", :name_prefix => "my_home_"}, {:name => "info", :name_prefix => "info_"}, {:name => "tags"}]' do
    @controller.stub!(:recognized_route).and_return(@routes[:my_home_info_tags])
    @controller.send(:resources_request).should == [{:name => "my_home", :name_prefix => "my_home_"}, {:name => "info", :name_prefix => "info_"}, {:name => "tags"}]
  end
  
  it ':my_home_post should be [{:name => "my_home", :name_prefix => "my_home_"}, {:name => "posts", :key => :id, :id => "1"}]' do
    @controller.stub!(:params).and_return(:id => "1")
    @controller.stub!(:recognized_route).and_return(@routes[:my_home_post])
    @controller.send(:resources_request).should == [{:name => "my_home", :name_prefix => "my_home_"}, {:name => "posts", :key => :id, :id => "1"}]
  end
  
  it ':forum_owner_post should be [{:name => "forums", :name_prefix => "forum_", :id => "1", :key => :forum_id}, {:name => "owner", :name_prefix => "owner_"}, {:name ="posts", :id => "2", :key => :id}]' do
    @controller.stub!(:params).and_return(:forum_id => "1", :id => "2")
    @controller.stub!(:recognized_route).and_return(@routes[:forum_owner_post])
    @controller.send(:resources_request).should == [{:name => "forums", :name_prefix => "forum_", :id => "1", :key => :forum_id}, {:name => "owner", :name_prefix => "owner_"}, {:name => "posts", :id => "2", :key => :id}]
  end
end