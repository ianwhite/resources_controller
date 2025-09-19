require 'spec_helper'

class ViewWithResourcesControllerHelper < ActionView::Base
  include ResourcesController::Helper
end

describe "ActionView with resources_controller Helper" do
  before do
    @view = ViewWithResourcesControllerHelper.new(ActionView::LookupContext.new([]), {}, nil)
    @controller = double('Controller')
    @view.controller = @controller
  end
  
  def self.it_should_forward_to_controller(msg, *args)
    it "should forward ##{msg}#{args.size > 0 ? "(#{args.join(',')})" : ""} to controller" do
      if args.empty?
        expect(@controller).to receive(msg).with(no_args)
      else
        expect(@controller).to receive(msg).with(*args)
      end
      @view.send(msg, *args)
    end
  end
  
  it_should_forward_to_controller :resource_name
  it_should_forward_to_controller :resources_name
  it_should_forward_to_controller :resource
  it_should_forward_to_controller :resources
  it_should_forward_to_controller :enclosing_resource
  it_should_forward_to_controller :enclosing_resource_name
  
  it 'should not forward unknown url helper to controller' do
    allow(@controller).to receive(:resource_named_route_helper_method?).and_return(false)
    expect(@controller).not_to receive(:resource_foo_path)
    expect { @view.send(:resource_foo_path) }.to raise_error(NoMethodError)
  end
end

describe "Helper#form_for_resource (when resource is new record)" do
  before do
    @view = ViewWithResourcesControllerHelper.new(ActionView::LookupContext.new([]), {}, nil)
    @controller = double('Controller')
    @specification = double('Specification')
    allow(@specification).to receive(:singleton?).and_return(false)
    @resource = double('Forum')
    @resource = double('Forum').as_null_object
    allow(@resource).to receive(:new_record?).and_return(true)
    allow(@controller).to receive(:resource).and_return(@resource)
    allow(@controller).to receive(:resource_name).and_return('forum')
    allow(@controller).to receive(:resources_path).and_return('/forums')
    allow(@controller).to receive(:resource_specification).and_return(@specification)
    allow(@controller).to receive(:resource_named_route_helper_method?).and_return(true)
    @view.controller = @controller
  end
  
  it 'should call form_for with create form options' do
    expect(@view).to receive(:form_for).with(@resource, {:as => 'forum', :html => {:method => :post}, :url => '/forums'})
    @view.form_for_resource{}
  end
  
  it 'when passed :url_options, they should be passed to the path generation' do
    expect(@view).to receive(:resources_path).with({:foo => 'bar'}).and_return('/forums?foo=bar')
    expect(@view).to receive(:form_for).with(@resource, {:as => 'forum', :html => {:method => :post}, :url => '/forums?foo=bar'})
    @view.form_for_resource(:url_options => {:foo => 'bar'}) {}
  end

  it 'when not passed :url_options, they should not be passed to the path generation' do
    expect(@view).to receive(:resources_path).with(no_args).and_return('/forums')
    expect(@view).to receive(:form_for).with(@resource, {:as => 'forum', :html => {:method => :post}, :url => '/forums'})
    @view.form_for_resource{}
  end
end

describe "Helper#form_for_resource (when resource is new record) and resource is singleton" do
  before do
    @view = ViewWithResourcesControllerHelper.new(ActionView::LookupContext.new([]), {}, nil)
    @controller = double('Controller')
    @specification = double('Specification')
    allow(@specification).to receive(:singleton?).and_return(true)
    @resource = double('Account')
    @resource = double('Account').as_null_object
    allow(@resource).to receive(:new_record?).and_return(true)
    allow(@controller).to receive(:resource).and_return(@resource)
    allow(@controller).to receive(:resource_name).and_return('account')
    allow(@controller).to receive(:resource_path).and_return('/account')
    allow(@controller).to receive(:resource_specification).and_return(@specification)
    allow(@controller).to receive(:resource_named_route_helper_method?).and_return(true)
    @view.controller = @controller
  end
  
  it 'should call form_for with create form options' do
    expect(@view).to receive(:form_for).with(@resource, {:as => 'account', :html => {:method => :post}, :url => '/account'})
    @view.form_for_resource{}
  end
end

describe "Helper#form_for_resource (when resource is existing record)" do
  before do
    @view = ViewWithResourcesControllerHelper.new(ActionView::LookupContext.new([]), {}, nil)
    @controller = double('Controller')
    @specification = double('Specification')
    allow(@specification).to receive(:singleton?).and_return(false)
    @resource = double('Forum').as_null_object
    allow(@resource).to receive(:new_record?).and_return(false)
    allow(@resource).to receive(:to_param).and_return("1")
    allow(@controller).to receive(:resource).and_return(@resource)
    allow(@controller).to receive(:resource_name).and_return('forum')
    allow(@controller).to receive(:resource_path).and_return('/forums/1')
    allow(@controller).to receive(:resource_specification).and_return(@specification)
    allow(@controller).to receive(:resource_named_route_helper_method?).and_return(true)
    @view.controller = @controller
  end
  
  it 'should call form_for with update form options' do
    expect(@view).to receive(:form_for).with(@resource, {:as => 'forum', :html => {:method => :put}, :url => '/forums/1'})
    @view.form_for_resource{}
  end
end
