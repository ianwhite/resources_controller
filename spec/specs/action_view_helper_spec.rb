require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '../app'))

class ViewWithResourcesControllerHelper < ActionView::Base
  include Ardes::ResourcesController::Helper
end

describe "ActionView with resources_controller Helper" do
  
  before do
    @view = ViewWithResourcesControllerHelper.new
    @controller = mock('Controller')
    @controller.stub!(:url_helper?).and_return(true)
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
  it_should_forward_to_controller :resources
  it_should_forward_to_controller :resource_url, 'resource'
  it_should_forward_to_controller :resource_url, 'resource', :foo => 'bar'
  it_should_forward_to_controller :edit_resource_url, 'resource'
  it_should_forward_to_controller :resources_url
  it_should_forward_to_controller :resources_url, :foo => 'bar'
  it_should_forward_to_controller :new_resource_url
  it_should_forward_to_controller :resource_path, 'resource'
  it_should_forward_to_controller :edit_resource_path, 'resource'
  it_should_forward_to_controller :resources_path
  it_should_forward_to_controller :new_resource_path
  
  
  # enclosed url helpers
  it_should_forward_to_controller :resource_tags_path
  it_should_forward_to_controller :resource_tags_path, 'resource_id'
  it_should_forward_to_controller :resource_tags_path, 'resource_id', :foo => 'bar'
  it_should_forward_to_controller :resource_tag_path, 'tag_id'
  it_should_forward_to_controller :resource_tag_path, 'resource_id', 'tag_id'
  it_should_forward_to_controller :resource_tag_path, 'resource_id', 'tag_id', :foo => 'bar'
  it_should_forward_to_controller :resource_tags_url
  it_should_forward_to_controller :resource_tags_url, 'resource_id'
  it_should_forward_to_controller :resource_tag_url, 'tag_id'
  it_should_forward_to_controller :resource_tag_url, 'resource_id', 'tag_id'

  it 'should not forward a badly formed method to the controller' do
    @controller.stub!(:url_helper?).and_return(false)
    @controller.should_not_receive(:badly_formed)
    lambda {@view.badly_formed}.should raise_error
  end
  
  it 'should not respond to badly formed method' do
    @controller.stub!(:url_helper?).and_return(false)
    @view.should_not respond_to(:badly_formed)
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
    @view.controller = @controller
  end
  
  it 'should call remote_form_for with update form options' do
    @view.should_receive(:remote_form_for).with('forum', @resource, {:html => {:method => :put}, :url => '/forums/1'})
    @view.remote_form_for_resource{}
  end
end