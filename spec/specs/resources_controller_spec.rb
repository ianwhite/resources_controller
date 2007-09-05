require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '../app'))

describe "ResourcesController#route_resource_names (route_name:tag, :singleton:false)" do
  before do
    @routes = ActionController::Routing::Routes.named_routes
    @controller = TagsController.new
    @controller.stub!(:route_name).and_return('tag')
    @controller.stub!(:singleton).and_return(false)
  end
  
  it ':tags should be []' do
    @controller.stub!(:recognized_route).and_return(@routes[:tags])
    @controller.send(:route_resource_names).should == []
  end

  it ':new_tag should be []' do
    @controller.stub!(:recognized_route).and_return(@routes[:new_tag])
    @controller.send(:route_resource_names).should == []
  end

  it ':edit_tag should be []' do
    @controller.stub!(:recognized_route).and_return(@routes[:edit_tag])
    @controller.send(:route_resource_names).should == []
  end

  it ':tag should be []' do
    @controller.stub!(:recognized_route).and_return(@routes[:tag])
    @controller.send(:route_resource_names).should == []
  end

  it ':forum_tags should be [["forums", false]]' do
    @controller.stub!(:recognized_route).and_return(@routes[:forum_tags])
    @controller.send(:route_resource_names).should == [["forums", false]]
  end

  it ':forum_tag should be [["forums", false]]' do
    @controller.stub!(:recognized_route).and_return(@routes[:forum_tag])
    @controller.send(:route_resource_names).should == [["forums", false]]
  end
  
  it ':user_addresses_tags should be [["users", false], ["addresses", false]]' do
    @controller.stub!(:recognized_route).and_return(@routes[:user_address_tags])
    @controller.send(:route_resource_names).should == [["users", false], ["addresses", false]]
  end

  it ':account_info_tags should be [["account", true], ["info", true]]' do
    @controller.stub!(:recognized_route).and_return(@routes[:account_info_tags])
    @controller.send(:route_resource_names).should == [["account", true], ["info", true]]
  end
  
  it ':new_account_info_tag should be [["account", true], ["info", true]]' do
    @controller.stub!(:recognized_route).and_return(@routes[:new_account_info_tag])
    @controller.send(:route_resource_names).should == [["account", true], ["info", true]]
  end
end