require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '../app'))

describe "ActionView with resources_controller Helper" do
  
  before do
    @view = mock('View')
    @view.extend Ardes::ResourcesController::Helper
    @controller = mock('Controller')
    @view.stub!(:controller).and_return(@controller)
  end
  
  def self.it_should_forward_to_controller(msg, *args)
    it "should forward ##{msg}#{args.size > 0 ? "(#{args.join(',')})" : ""} to controller" do
      @controller.should_receive(msg).with(*args)
      @view.send(msg, *args)
    end
  end
  
  it_should_forward_to_controller :resource_name
  it_should_forward_to_controller :resources_name
  it_should_forward_to_controller :resource
  it_should_forward_to_controller :resources
  it_should_forward_to_controller :resource_url, '*resource'
  it_should_forward_to_controller :edit_resource_url, '*resource'
  it_should_forward_to_controller :resources_url
  it_should_forward_to_controller :new_resource_url
  it_should_forward_to_controller :resource_path, '*resource'
  it_should_forward_to_controller :edit_resource_path, '*resource'
  it_should_forward_to_controller :resources_path
  it_should_forward_to_controller :new_resource_path
end