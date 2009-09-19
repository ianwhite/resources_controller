require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '../app'))

module LoadEnclosingResourcesSpecHelper
  def setup_tags_controller(options = {})
    @klass = Class.new(ActionController::Base)
    @klass.resources_controller_for :tags, options
    setup_common
  end

  def setup_common
    @controller = @klass.new
    @controller.stub!(:request_path).and_return('')
    # stub :load_enclosing_resource_from_specification, increase enclosing_resources by one, and return a mock resource
    @controller.stub!(:load_enclosing_resource_from_specification).and_return do |name, _|
      returning mock("resource: #{name}") do |resource|
        @controller.enclosing_resources << resource
      end
    end
  end
end

describe "#load_enclosing_resources for resources_controller_for :tags (when nesting_segments is [{:segment => 'users', :singleton => false}])" do
  include LoadEnclosingResourcesSpecHelper

  before do
    setup_tags_controller
    @controller.stub!(:nesting_segments).and_return [{:segment => 'users', :singleton => false}]
  end
    
  it "should call load_wildcard once" do
    @controller.should_receive(:load_wildcard).once
    @controller.send(:load_enclosing_resources)
  end
  
  it "should call Specification.new('user', :singleton => false, :as => nil)" do
    Ardes::ResourcesController::Specification.should_receive(:new).with('user', :singleton => false, :as => nil)
    @controller.send(:load_enclosing_resources)
  end
end

describe "#load_enclosing_resources for resources_controller_for :tags, with :account mapping (when nesting_segments is [{:segment => 'account', :singleton => true}])" do
  include LoadEnclosingResourcesSpecHelper

  before do
    setup_tags_controller
    @klass.map_resource :account, :singleton => true, :class => User
    @account_spec = @controller.resource_specification_map['account']
    @controller.stub!(:nesting_segments).and_return [{:segment => 'account', :singleton => true}]
  end
    
  it "should call load_wildcard once" do
    @controller.should_receive(:load_wildcard).once
    @controller.send(:load_enclosing_resources)
  end
  
  it "should call load_enclosing_resource_from_specification with account specification" do
    @controller.should_receive(:load_enclosing_resource_from_specification).with(@account_spec)
    @controller.send(:load_enclosing_resources)
  end
  
  it "should not call Specification.new" do
    Ardes::ResourcesController::Specification.should_not_receive(:new)
    @controller.send(:load_enclosing_resources)
  end
end

describe "#load_enclosing_resources for resources_controller_for :tags (when nesting_segments is [{:segment =>'users', :singleton => false}, {:segment =>'forums', :singleton => false}])" do
  include LoadEnclosingResourcesSpecHelper

  before do
    setup_tags_controller
    @controller.stub!(:nesting_segments).and_return [{:segment =>'users', :singleton => false}, {:segment =>'forums', :singleton => false}]
  end
    
  it "should call load_wildcard twice" do
    @controller.should_receive(:load_wildcard).twice
    @controller.send(:load_enclosing_resources)
  end
  
  it "should call Specification.new with ('user', :singleton => false, :as => nil), then ('forum', :singleton => false, :as => nil)" do
    Ardes::ResourcesController::Specification.should_receive(:new).with('user', :singleton => false, :as => nil).ordered
    Ardes::ResourcesController::Specification.should_receive(:new).with('forum', :singleton => false, :as => nil).ordered
    @controller.send(:load_enclosing_resources)
  end
end

describe "#load_enclosing_resources for resources_controller_for :tags, :in => ['*', :comment] (when nesting_segments is [{:segment => 'comments', :singleton => false}])" do
  include LoadEnclosingResourcesSpecHelper

  before do
    setup_tags_controller :in => ['*', :comment]
    @controller.stub!(:nesting_segments).and_return [{:segment => 'comments', :singleton => false}]
  end
  
  it "should not call load_wildcard" do
    @controller.should_not_receive(:load_wildcard)
    @controller.send(:load_enclosing_resources)
  end
  
  it "should not call Specification.new" do
    Ardes::ResourcesController::Specification.should_not_receive(:new)
    @controller.send(:load_enclosing_resources)
  end
end

describe "#load_enclosing_resources for resources_controller_for :tags, :in => ['*', :comment] (when nesting_segments is [{:segment => 'users', :singleton => false}, {:segment => 'forums', :singleton => false}, {:segment =>'comments', :singleton => false}])" do
  include LoadEnclosingResourcesSpecHelper

  before do
    setup_tags_controller :in => ['*', :comment]
    @controller.stub!(:nesting_segments).and_return [{:segment => 'users', :singleton => false}, {:segment => 'forums', :singleton => false}, {:segment =>'comments', :singleton => false}]
  end
  
  it "should call load_wildcard twice" do
    @controller.should_receive(:load_wildcard).twice
    @controller.send(:load_enclosing_resources)
  end
  
  it "should call Specification.new with ('user', :singleton => false, :as => nil), then ('forum', :singleton => false, :as => nil)" do
    Ardes::ResourcesController::Specification.should_receive(:new).with('user', :singleton => false, :as => nil).ordered
    Ardes::ResourcesController::Specification.should_receive(:new).with('forum', :singleton => false, :as => nil).ordered
    @controller.send(:load_enclosing_resources)
  end
end

describe "#load_enclosing_resources for resources_controller_for :tags, :in => ['*', '?commentable', :comment] (when nesting_segments is [{:segment => 'users', :singleton => false}, {:segment => 'comments', :singleton => false}])" do
  include LoadEnclosingResourcesSpecHelper

  before do
    setup_tags_controller :in => ['*', '?commentable', :comment]
    @controller.stub!(:nesting_segments).and_return [{:segment => 'users', :singleton => false}, {:segment => 'comments', :singleton => false}]
  end
  
  it "should call load_wildcard once with 'commentable'" do
    @controller.should_receive(:load_wildcard).with('commentable').once
    @controller.send(:load_enclosing_resources)
  end
  
  it "should call Specification.new with ('user', :singleton => false, :as => 'commentable')" do
    Ardes::ResourcesController::Specification.should_receive(:new).with('user', :singleton => false, :as => 'commentable').ordered
    @controller.send(:load_enclosing_resources)
  end
end

describe "#load_enclosing_resources for resources_controller_for :tags, :in => ['*', '?commentable', :comment] (when nesting_segments is [{:segment => 'users', :singleton => false}, {:segment => 'forums', :singleton => false}, {:segment => 'comments', :singleton => false}])" do
  include LoadEnclosingResourcesSpecHelper

  before do
    setup_tags_controller :in => ['*', '?commentable', :comment]
    @controller.stub!(:nesting_segments).and_return [{:segment => 'users', :singleton => false}, {:segment => 'forums', :singleton => false}, {:segment => 'comments', :singleton => false}]
  end
  
  it "should call load_wildcard twice" do
    @controller.should_receive(:load_wildcard).with().once.ordered
    @controller.should_receive(:load_wildcard).with('commentable').once.ordered
    @controller.send(:load_enclosing_resources)
  end
  
  it "should call Specification.new with ('user', :singleton => false, :as => nil), ('forum', :singleton => false, :as => 'commentable')" do
    Ardes::ResourcesController::Specification.should_receive(:new).with('user', :singleton => false, :as => nil).once.ordered
    Ardes::ResourcesController::Specification.should_receive(:new).with('forum', :singleton => false, :as => 'commentable').once.ordered
    @controller.send(:load_enclosing_resources)
  end
end

describe "#load_enclosing_resources for resources_controller_for :tags, :in => ['*', '?commentable', :comment] (when nesting_segments is [{:segment => 'users', :singleton => false}, {:segment => 'forums', :singleton => false}, {:segment => 'posts', :singleton => false}, {:segment => 'comments', :singleton => false}])" do
  include LoadEnclosingResourcesSpecHelper

  before do
    setup_tags_controller :in => ['*', '?commentable', :comment]
    @controller.stub!(:nesting_segments).and_return [{:segment => 'users', :singleton => false}, {:segment => 'forums', :singleton => false}, {:segment => 'posts', :singleton => false}, {:segment => 'comments', :singleton => false}]
  end
  
  it "should call load_wildcard twice, then once with 'commentable'" do
    @controller.should_receive(:load_wildcard).with().twice.ordered
    @controller.should_receive(:load_wildcard).with('commentable').once.ordered
    @controller.send(:load_enclosing_resources)
  end
  
  it "should call Specification.new with ('user', :singleton => false, :as => nil), ('forum', :singleton => false, :as => nil), then ('post', :singleton => false, :as => 'commentable')" do
    Ardes::ResourcesController::Specification.should_receive(:new).with('user', :singleton => false, :as => nil).once.ordered
    Ardes::ResourcesController::Specification.should_receive(:new).with('forum', :singleton => false, :as => nil).once.ordered
    Ardes::ResourcesController::Specification.should_receive(:new).with('post', :singleton => false, :as => 'commentable').once.ordered
    @controller.send(:load_enclosing_resources)
  end
end

describe "#load_enclosing_resources for resources_controller_for :tags, :in => ['user', '*', '?taggable'] (when nesting_segments is [{:segment => 'users', :singleton => false}, {:segment => 'comments', :singleton => false}])" do
  include LoadEnclosingResourcesSpecHelper

  before do
    setup_tags_controller :in => ['user', '*', '?taggable']
    @user_spec = @controller.send(:specifications)[1]
    @controller.stub!(:nesting_segments).and_return [{:segment => 'users', :singleton => false}, {:segment => 'comments', :singleton => false}]
  end
  
  it "should call load_enclosing_resource_from_specification with user spec, then load_wildcard once with 'taggable'" do
    @controller.should_receive(:load_enclosing_resource_from_specification).with(@user_spec).once.ordered do
      returning(mock('user')){|r| @controller.enclosing_resources << r }
    end
    @controller.should_receive(:load_wildcard).with('taggable').once.ordered
    @controller.send(:load_enclosing_resources)
  end
  
  it "should call Specification.new with ('comment', :singleton => false, :as => 'taggable')" do
    Ardes::ResourcesController::Specification.should_receive(:new).with('comment', :singleton => false, :as => 'taggable').ordered
    @controller.send(:load_enclosing_resources)
  end
end

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
