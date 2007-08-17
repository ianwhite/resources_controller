require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '../app'))

describe "A controller's resource_service" do
  
  before do
    @controller = ForumsController.new
  end
    
  it 'may be explicitly set with #resource_service=' do
    @controller.resource_service = 'foo'
    @controller.resource_service.should == 'foo'
  end
end