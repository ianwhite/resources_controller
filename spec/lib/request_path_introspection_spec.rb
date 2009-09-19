require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))

module RequestPathIntrospectionSpec
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
      
      it "should remove only the controller_name segment, when nesting is same name" do
        @controller.stub!(:request_path).and_return('/forums/1/forums/2')
        @controller.send(:nesting_request_path).should == '/forums/1'
      end
      
      it "should remove any controller namespace" do
        @controller.stub!(:controller_path).and_return('some/name/space/forums')
        @controller.stub!(:request_path).and_return('/some/name/space/users/1/secret/forums')
        @controller.send(:nesting_request_path).should == '/users/1/secret'
      end
    end
  end
end