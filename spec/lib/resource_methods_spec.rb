require 'spec_helper'

module ResourceMethodsSpec
  class MyController < ActionController::Base
    resources_controller_for :users
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
  
  describe "An rc for collection :users" do
    before do
      @controller = MyController.new
      @controller.stub!(:params).and_return({})
    end

    describe "when no enclosing resource" do
      it "#find_resource(<id>) should call User.find(<id>)" do
        User.should_receive(:find).with("42")
        @controller.send(:find_resource, "42")
      end
    
      it "#find_resources should call User.find(:all)" do
        User.should_receive(:all)
        @controller.send(:find_resources)
      end

      it "#new_resource({}) should call User.new({})" do
        User.should_receive(:new).with({})
        @controller.send(:new_resource, {})
      end

      it "#destroy_resource(<id>) should call User.find(<id>).destroy" do
        User.should_receive(:find).with("42").and_return(user = mock)
        user.should_receive(:destroy).and_return(user)
        @controller.send(:destroy_resource, "42").should == user
      end
    end
      
    describe "when an enclosing resource is added (a forum)" do
      before do
        @forum = Forum.create!
        @forum.stub(:users).and_return(@users = double)
        @controller.send :add_enclosing_resource, @forum
      end
  
      it "#find_resource(<id>) should find the forum user" do
        @users.should_receive(:find).with("42").and_return(user = double)
        @controller.send(:find_resource, "42").should == user
      end
  
      it "#find_resources should return the forum users" do
        @users.should_receive(:all).and_return(users = double)
        @controller.send(:find_resources).should == users
      end

      it "#new_resource({}) should call forum.users.build({})" do
        @users.should_receive(:build).with({}).and_return(user = double)
        @controller.send(:new_resource, {}).should == user
      end

      it "#destroy_resource(<id>) should call forum.users.find(<id>) and forum.users.destroy(<id>) and return the resource" do
        @users.should_receive(:find).with("42").and_return(user = double)
        @users.should_receive(:destroy).with("42")
        @controller.send(:destroy_resource, "42").should == user
      end
    end
  end
  
  class MySingletonController < ActionController::Base
    resources_controller_for :info, :singleton => true
  end
  
  describe "An rc for singleton :info" do
    before do
      @controller = MySingletonController.new
      @controller.stub!(:params).and_return({})
    end
      
    describe "with an enclosing resource (a user)" do
      before do
        @user = User.create!
        @controller.send :add_enclosing_resource, @user
      end
  
      it "#find_resource should call user.info" do
        @user.should_receive(:info)
        @controller.send(:find_resource)
      end

      it "#new_resource({}) should call user.build_info({})" do
        @user.should_receive(:build_info).with({})
        @controller.send :new_resource, {}
      end

      it "#destroy_resource should call user.info.destroy" do
        @user.should_receive(:info).and_return(info = mock)
        info.should_receive(:destroy)
        @controller.send(:destroy_resource)
      end
    end
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
    
    def destroy_resource(id = params[:id])
      "my destroy_resource"
    end
  end

  shared_examples_for "A controller with its own resource methods" do
    it "#new_resource should call MyResourceMethods#new_resource" do
      @controller.send(:new_resource, {}).should == 'my new_resource'
    end

    it "#find_resource should call MyResourceMethods#find_resource" do
      @controller.send(:find_resource, 1).should == 'my find_resource'
    end

    it "#find_resources should call MyResourceMethods#new_resource" do
      @controller.send(:find_resources).should == 'my find_resources'
    end
    
    it "#destroy_resource should call MyResourceMethods#destroy_resource" do
      @controller.send(:destroy_resource, 1).should == 'my destroy_resource'
    end
  end
  
  class MyControllerWithMyResourceMethodsMixedIn < ActionController::Base
    resources_controller_for :users
    include MyResourceMethods
  end
  
  describe "A controller with resource methods mixed in after resources_controller_for" do
    before do
      @controller = MyControllerWithMyResourceMethodsMixedIn.new
      @controller.resource_service = User
      @controller.stub!(:params).and_return({})
    end
    
    it_should_behave_like "A controller with its own resource methods"
  end
  
  class MyAbstractControllerWithOwnResourceMethods < ActionController::Base
    include MyResourceMethods
  end
  
  class InhertedMyAbstractControllerWithOwnResourceMethods < MyAbstractControllerWithOwnResourceMethods
    resources_controller_for :users, :resource_methods => false
  end
  
  describe "A controller inheriting resource methods which declares :resource_methods => false" do
    before do
      @controller = InhertedMyAbstractControllerWithOwnResourceMethods.new
      @controller.resource_service = User
      @controller.stub!(:params).and_return({})
    end
    
    it_should_behave_like "A controller with its own resource methods"
  end
  
  class MyAbstractControllerWithResourceMethodsOverridden < ActionController::Base
    include ResourcesController::ResourceMethods
    include MyResourceMethods
  end
  
  class InhertedMyAbstractControllerWithResourceMethodsOverridden < MyAbstractControllerWithResourceMethodsOverridden
    resources_controller_for :users
  end
  
  describe "A controller inheriting from a controller which mixes in ResourceMethods, and overrides them" do
    before do
      @controller = InhertedMyAbstractControllerWithResourceMethodsOverridden.new
      @controller.resource_service = User
      @controller.stub!(:params).and_return({})
    end
    
    it_should_behave_like "A controller with its own resource methods"
  end
end