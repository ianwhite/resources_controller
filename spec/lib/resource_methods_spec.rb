require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '../app'))

module ResourceMethodsSpec
  class MyController < ActionController::Base
    resources_controller_for :users
  end
  
  module MyResourceMethods
  
  protected
    def new_resource(attrs = (params[resource_name] || {}), &block)
      "my new_resource"
    end
    
    def find_resource(id = params[:id])
      "my find_resource"
      
    end
    
    def find_resources
      "my find_resources"
    end
  end
  
  class MyControllerWithMyResourceMethods < ActionController::Base
    resources_controller_for :users
    include MyResourceMethods
  end
  
  if Rails.respond_to?(:version) && Rails.version >= "2.3"
    describe "#new_resource" do
      it "should accept block syntax" do
        c = MyController.new
        c.resource_service = User
        c.stub!(:params).and_return({})
        r = c.send(:new_resource) do |u|
          u.login = "Fred"
        end
        r.should be_kind_of User
        r.login.should == "Fred"
      end
    end
  end
  
  describe "A controller with resource methods mixed in after resources_controller_for" do
    before do
      @controller = MyControllerWithMyResourceMethods.new
      @controller.resource_service = User
    end
    
    it "#new_resource should call MyResourceMethods#new_resource" do
      @controller.send(:new_resource, {}).should == 'my new_resource'
    end

    it "#find_resource should call MyResourceMethods#find_resource" do
      @controller.send(:find_resource, 1).should == 'my find_resource'
    end

    it "#find_resources should call MyResourceMethods#new_resource" do
      @controller.send(:find_resources).should == 'my find_resources'
    end
  end
end