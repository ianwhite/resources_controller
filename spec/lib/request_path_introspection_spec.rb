require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))

module RequestPathIntrospectionSpec
  class Forum < ActiveRecord::Base; end
  
  class User < ActiveRecord::Base; end
  
  describe "RequestPathIntrospection" do
    before do
      @klass = Class.new(ActionController::Base)
      @controller = @klass.new
      @controller.stub!(:controller_name).and_return('forums')
      @controller.stub!(:controller_path).and_return('forums')
      @controller.stub!(:params).and_return({})
      @controller.stub!(:request).and_return(mock('request', :path => '/forums'))
    end
    
    describe "#request_path" do
      it "should default to request.path" do
        @controller.send(:request_path).should == '/forums'
      end
      
      it " should be params[:resource_path], when set" do
        @controller.params[:resource_path] = '/foo'
        @controller.send(:request_path).should == '/foo'
      end
    end
    
    describe "#nesting_request_path" do
      it "should remove the controller_name segment" do
        @controller.stub!(:request_path).and_return('/users/1/forums/2')
        @controller.send(:nesting_request_path).should == '/users/1'
      end
      
      it "when resource_specification present, whould remove taht segment" do
        @controller.stub!(:resource_specification).and_return(Ardes::ResourcesController::Specification.new(:forum, :class => RequestPathIntrospectionSpec::Forum, :segment => 'foromas'))
        @controller.stub!(:request_path).and_return('/users/1/foromas/2')
        @controller.send(:nesting_request_path).should == '/users/1'
      end
      
      it "should remove only the controller_name segment, when nesting is same name" do
        @controller.stub!(:request_path).and_return('/forums/1/forums/2')
        @controller.send(:nesting_request_path).should == '/forums/1'
      end

      it "should remove the controller_name segment, even when id matches controller name" do
        @controller.stub!(:request_path).and_return('/forums/1/forums/forums.atom')
        @controller.send(:nesting_request_path).should == '/forums/1'
      end

      it "should remove only the controller_name segment even when nesting is same name" do
        @controller.stub!(:resource_specification).and_return(Ardes::ResourcesController::Specification.new(:forum, :class => RequestPathIntrospectionSpec::Forum, :singleton => true))
        @controller.stub!(:request_path).and_return('/users/1/forum/forum.atom')
        @controller.send(:nesting_request_path).should == '/users/1/forum'
      end
      
      it "should remove any controller namespace" do
        @controller.stub!(:controller_path).and_return('some/name/space/forums')
        @controller.stub!(:request_path).and_return('/some/name/space/users/1/secret/forums')
        @controller.send(:nesting_request_path).should == '/users/1/secret'
      end
    end
    
    it "#namespace_segments should return [] segments if NOT present in request_path" do
      @controller.stub!(:controller_path).and_return('some/name/space/forums')
      @controller.stub!(:request_path).and_return('/SAM/name/space/users/1/secret/forums')
      @controller.send(:namespace_segments).should == []
    end
    
    it "#namespace_segments should return namespace segments if present in request_path" do
      @controller.stub!(:controller_path).and_return('some/name/space/forums')
      @controller.stub!(:request_path).and_return('/some/name/space/users/1/secret/forums')
      @controller.send(:namespace_segments).should == ['some', 'name', 'space']
    end
    
    describe "#nesting_segments" do
      describe "when params include :user_id" do
        before do
          @controller.params[:user_id] = '1'
        end
        
        it "and request path is '/users/1/forums', should return [{:segment => 'users', :singleton => false}]" do
          @controller.request.stub!(:path).and_return('/users/1/forums')
          @controller.send(:nesting_segments).should == [{:segment => 'users', :singleton => false}]
        end
        
        it "and request path is '/account/users/1/forums', should return [{:segment => 'account', :singleton => true}, {:segment => 'users', :singleton => false}]" do
          @controller.request.stub!(:path).and_return('/account/users/1/forums')
          @controller.send(:nesting_segments).should == [{:segment => 'account', :singleton => true}, {:segment => 'users', :singleton => false}]
        end
        
        describe "when controller has nesting for :user => 'muchachos'" do
          before do
            @klass.resources_controller_for :forums, :class => RequestPathIntrospectionSpec::Forum
            @klass.nested_in :user, :segment => "muchachos", :class => RequestPathIntrospectionSpec::User
          end
          
          it "and request path is '/muchachos/1/forums', should return [{:segment => 'muchachos', :singleton => false}]" do
            @controller.request.stub!(:path).and_return('/muchachos/1/forums')
            @controller.send(:nesting_segments).should == [{:segment => 'muchachos', :singleton => false}]
          end
        end
        
        describe "when enclosing resource has mapping for :user => 'muchachos'" do
          before do
            @klass.map_enclosing_resource :user, :segment => "muchachos", :class => RequestPathIntrospectionSpec::User
          end
          
          it "and request path is '/muchachos/1/forums', should return [{:segment => 'muchachos', :singleton => false}]" do
            @controller.request.stub!(:path).and_return('/muchachos/1/forums')
            @controller.send(:nesting_segments).should == [{:segment => 'muchachos', :singleton => false}]
          end
        end
      end
    end
  
    describe "#segment_for_key" do
      describe "when controller has map {:user, :singelton => true}" do
        before do
          @klass.resources_controller_for :forums, :class => RequestPathIntrospectionSpec::Forum
          @klass.map_enclosing_resource :user, :singleton => true, :class => RequestPathIntrospectionSpec::User
        end
        
        it "('user_id') should return 'users'" do
          @controller.send(:segment_for_key, 'user_id').should == 'users'
        end
      end
    end
  end
end