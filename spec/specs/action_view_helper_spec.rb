require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '../app'))

class ViewWithResourcesControllerHelper < ActionView::Base
  include Ardes::ResourcesController::Helper
end

describe "ActionView with resources_controller Helper" do
  before do
    @view = ViewWithResourcesControllerHelper.new
    @controller = mock('Controller')
    @view.controller = @controller
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
  it_should_forward_to_controller :enclosing_resource
  
  it 'should not forward unknown url helper to controller' do
    @controller.stub!(:resource_named_route_helper_method?).and_return(false)
    @controller.should_not_receive(:resource_foo_path)
    lambda { @view.send(:resource_foo_path) }.should raise_error(NoMethodError)
  end
end

describe "Helper#form_for_resource (when resource is new record)" do
  before do
    @view = ViewWithResourcesControllerHelper.new
    @controller = mock('Controller')
    @resource = mock('Forum')
    @resource = mock('Forum', :null_object => true)
    @resource.stub!(:new_record?).and_return(true)
    @controller.stub!(:resource).and_return(@resource)
    @controller.stub!(:resource_name).and_return('forum')
    @controller.stub!(:resources_path).and_return('/forums')
    @controller.stub!(:resource_named_route_helper_method?).and_return(true)
    @view.controller = @controller
  end
  
  it 'should call form_for with create form options' do
    @view.should_receive(:form_for).with('forum', @resource, {:html => {:method => :post}, :url => '/forums'})
    @view.form_for_resource{}
  end
end

describe "Helper#form_for_resource (when resource is existing record)" do
  before do
    @view = ViewWithResourcesControllerHelper.new
    @controller = mock('Controller')
    @resource = mock('Forum', :null_object => true)
    @resource.stub!(:new_record?).and_return(false)
    @resource.stub!(:to_param).and_return("1")
    @controller.stub!(:resource).and_return(@resource)
    @controller.stub!(:resource_name).and_return('forum')
    @controller.stub!(:resource_path).and_return('/forums/1')
    @controller.stub!(:resource_named_route_helper_method?).and_return(true)
    @view.controller = @controller
  end
  
  it 'should call form_for with update form options' do
    @view.should_receive(:form_for).with('forum', @resource, {:html => {:method => :put}, :url => '/forums/1'})
    @view.form_for_resource{}
  end
end

describe "Helper#remote_form_for_resource (when resource is existing record)" do
  before do
    @view = ViewWithResourcesControllerHelper.new
    @controller = mock('Controller')
    @resource = mock('Forum', :null_object => true)
    @resource.stub!(:new_record?).and_return(false)
    @resource.stub!(:to_param).and_return("1")
    @controller.stub!(:resource).and_return(@resource)
    @controller.stub!(:resource_name).and_return('forum')
    @controller.stub!(:resource_path).and_return('/forums/1')
    @controller.stub!(:resource_named_route_helper_method?).and_return(true)
    @view.controller = @controller
  end
  
  it 'should call remote_form_for with update form options' do
    @view.should_receive(:remote_form_for).with('forum', @resource, {:html => {:method => :put}, :url => '/forums/1'})
    @view.remote_form_for_resource{}
  end
end