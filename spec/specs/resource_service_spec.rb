require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '../app'))

describe "A controller's resource_service" do
  
  before do
    Forum.stub!(:gday)
    @controller = ForumsController.new
    @service = @controller.resource_service
  end
  
  it 'should pass unknown methods to the resource service of the controller' do
    Forum.should_receive(:gday)
    @service.gday
  end
  
  it 'may be explicitly set with #resource_service=' do
    @controller.resource_service = 'foo'
    @controller.resource_service.should == 'foo'
  end
end