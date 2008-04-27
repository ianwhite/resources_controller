require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '../app'))

# specing some branching BC code
# find_filter dissapeared from edge, but we want to support it for 2.0-stable
describe "ResourcesController.load_enclosing_resources_filter_exists?" do
  before do
    @klass = Class.new(ActionController::Base)
  end
  
  describe "when :find_filter defined" do
    before do
      class<<@klass
        def find_filter; end
      end
    end
    
    it "should call :find_filter with :load_enclosing_resources" do
      @klass.should_receive(:find_filter).with(:load_enclosing_resources)
      @klass.send(:load_enclosing_resources_filter_exists?)
    end
  end
  
  describe "when :find_filter not defined" do
    before do
      class<<@klass
        undef_method(:find_filter) rescue nil
      end
    end
        
    it "should call :filter_chain" do
      @klass.should_receive(:filter_chain).and_return([])
      @klass.send(:load_enclosing_resources_filter_exists?)
    end
  end
end