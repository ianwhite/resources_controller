require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '../app'))

describe "ResourcesController#resources_request" do
  before do
    @controller = ForumsController.new
    @request = mock('request')
    @controller.request = @request
  end
  
  it 'should be [] for /users' do
    @request.stub!(:path).and_return('/users')
    @controller.send(:resources_request).should == []
  end

  it 'should be [[users, id]] for /users/id' do
    @request.stub!(:path).and_return('/users/id')
    @controller.send(:resources_request).should == [['users', 'id']]
  end
  
  it 'should be [[users, id]] for /users/id/foos' do
    @request.stub!(:path).and_return('/users/id/foos')
    @controller.send(:resources_request).should == [['users', 'id']]
  end

  it 'should be [[users, id], [foos, id]] for /users/id/foos/id' do
    @request.stub!(:path).and_return('/users/id/foos/id')
    @controller.send(:resources_request).should == [['users', 'id'], ['foos', 'id']]
  end  
end