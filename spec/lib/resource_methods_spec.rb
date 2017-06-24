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
        allow(c).to receive(:params).and_return({})
        r = c.send(:new_resource) do |u|
          u.login = "Fred"
        end
        expect(r).to be_kind_of User
        expect(r.login).to eq("Fred")
      end
    end
  end
  
  describe "An rc for collection :users" do
    before do
      @controller = MyController.new
      allow(@controller).to receive(:params).and_return({})
    end

    describe "when no enclosing resource" do
      it "#find_resource(<id>) should call User.find(<id>)" do
        expect(User).to receive(:find).with("42")
        @controller.send(:find_resource, "42")
      end
    
      it "#find_resources should call User.find(:all)" do
        expect(User).to receive(:all)
        @controller.send(:find_resources)
      end

      it "#new_resource({}) should call User.new({})" do
        expect(User).to receive(:new).with({})
        @controller.send(:new_resource, {})
      end

      it "#destroy_resource(<id>) should call User.find(<id>).destroy" do
        expect(User).to receive(:find).with("42").and_return(user = double)
        expect(user).to receive(:destroy).and_return(user)
        expect(@controller.send(:destroy_resource, "42")).to eq(user)
      end
    end
      
    describe "when an enclosing resource is added (a forum)" do
      before do
        @forum = Forum.create!
        allow(@forum).to receive(:users).and_return(@users = double)
        @controller.send :add_enclosing_resource, @forum
      end
  
      it "#find_resource(<id>) should find the forum user" do
        expect(@users).to receive(:find).with("42").and_return(user = double)
        expect(@controller.send(:find_resource, "42")).to eq(user)
      end
  
      it "#find_resources should return the forum users" do
        expect(@users).to receive(:all).and_return(users = double)
        expect(@controller.send(:find_resources)).to eq(users)
      end

      it "#new_resource({}) should call forum.users.build({})" do
        expect(@users).to receive(:build).with({}).and_return(user = double)
        expect(@controller.send(:new_resource, {})).to eq(user)
      end

      it "#destroy_resource(<id>) should call forum.users.find(<id>) and forum.users.destroy(<id>) and return the resource" do
        expect(@users).to receive(:find).with("42").and_return(user = double)
        expect(@users).to receive(:destroy).with("42")
        expect(@controller.send(:destroy_resource, "42")).to eq(user)
      end
    end
  end
  
  class MySingletonController < ActionController::Base
    resources_controller_for :info, :singleton => true
  end
  
  describe "An rc for singleton :info" do
    before do
      @controller = MySingletonController.new
      allow(@controller).to receive(:params).and_return({})
    end
      
    describe "with an enclosing resource (a user)" do
      before do
        @user = User.create!
        @controller.send :add_enclosing_resource, @user
      end
  
      it "#find_resource should call user.info" do
        expect(@user).to receive(:info)
        @controller.send(:find_resource)
      end

      it "#new_resource({}) should call user.build_info({})" do
        expect(@user).to receive(:build_info).with({})
        @controller.send :new_resource, {}
      end

      it "#destroy_resource should call user.info.destroy" do
        expect(@user).to receive(:info).and_return(info = double)
        expect(info).to receive(:destroy)
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
      expect(@controller.send(:new_resource, {})).to eq('my new_resource')
    end

    it "#find_resource should call MyResourceMethods#find_resource" do
      expect(@controller.send(:find_resource, 1)).to eq('my find_resource')
    end

    it "#find_resources should call MyResourceMethods#new_resource" do
      expect(@controller.send(:find_resources)).to eq('my find_resources')
    end
    
    it "#destroy_resource should call MyResourceMethods#destroy_resource" do
      expect(@controller.send(:destroy_resource, 1)).to eq('my destroy_resource')
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
      allow(@controller).to receive(:params).and_return({})
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
      allow(@controller).to receive(:params).and_return({})
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
      allow(@controller).to receive(:params).and_return({})
    end
    
    it_should_behave_like "A controller with its own resource methods"
  end
end
