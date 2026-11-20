require 'spec_helper'

describe "ResourcesController::NamedRouteHelper" do
  before do
    @controller = ForumsController.new
  end

  it "should respond to a named route helper for the current resource" do
    expect(@controller.respond_to?(:resource_path)).to eq(true)
    expect(@controller.respond_to?(:resources_path)).to eq(true)
  end

  it "should not respond to something that is not a named route helper" do
    expect(@controller.respond_to?(:resource_nonexistent_path)).to eq(false)
    expect(@controller.respond_to?(:not_a_route_path)).to eq(false)
  end

  # this works because the module defines respond_to_missing?, not respond_to?
  it "should expose named route helpers through #method" do
    expect(@controller.method(:resource_path)).to be_a(Method)
  end

  it "should check route availability without querying named_routes" do
    fresh_class = Class.new(ApplicationController) do
      resources_controller_for :forums
    end
    fresh_controller = fresh_class.new
    expect(Rails.application.routes.named_routes).not_to receive(:get)
    expect(fresh_controller.respond_to?(:resource_path)).to eq(true)
    expect(fresh_controller.respond_to?(:resource_nonexistent_path)).to eq(false)
  end

  it "should forward keyword arguments through newly defined named route helpers and super" do
    fresh_class = Class.new(ApplicationController) do
      resources_controller_for :forums

      def method_missing(method, *args, **kwargs, &block)
        return [method, args, kwargs, block&.call] if method == :custom_missing_with_forward

        super
      end
    end
    fresh_controller = fresh_class.new
    fresh_controller.request = ActionDispatch::TestRequest.create
    fresh_controller.resource = Forum.new(:id => 2)

    expect(fresh_controller.resource_path(foo: 'bar')).to eq('/forums/2?foo=bar')
    expect(fresh_controller.custom_missing_with_forward(1, key: 'val') { :yielded }).to eq(
      [:custom_missing_with_forward, [1], {:key => 'val'}, :yielded]
    )
  end

  it "should handle nil name_prefix in generated named route helpers" do
    fresh_class = Class.new(ApplicationController) do
      resources_controller_for :forums

      def name_prefix
        nil
      end
    end
    fresh_controller = fresh_class.new
    fresh_controller.request = ActionDispatch::TestRequest.create
    fresh_controller.resource = Forum.new(:id => 2)

    expect(fresh_controller.resource_path).to eq('/forums/2')
  end

  it "should merge default_url_options into generated route helpers" do
    @controller.request = ActionDispatch::TestRequest.create
    @controller.resource = Forum.new(:id => 2)
    allow(@controller).to receive(:default_url_options).and_return(:locale => 'en')

    expect(@controller.resources_path).to eq('/forums?locale=en')
    expect(@controller.resource_path(:foo => 'bar')).to eq('/forums/2?foo=bar&locale=en')
  end

  it "should merge default_url_options into enclosing route helpers" do
    tag_controller = TagsController.new
    tag_controller.request = ActionDispatch::TestRequest.create
    forum = Forum.new(:id => 1)
    tag_controller.send(:add_enclosing_resource, forum, :name => 'forum')
    allow(tag_controller).to receive(:default_url_options).and_return(:locale => 'en')

    expect(tag_controller.enclosing_resource_path).to eq('/forums/1?locale=en')
    expect(tag_controller.enclosing_resource_path(9, :foo => 'bar')).to eq('/forums/9?foo=bar&locale=en')
  end

  it "should dispatch cached prefixes directly across multiple nestings without method_missing" do
    fresh_class = Class.new(ApplicationController) do
      resources_controller_for :tags
    end
    sub_class = Class.new(fresh_class)
    forum = Forum.new(:id => 1)
    post = Post.new(:id => 2)
    tag = Tag.new(:id => 3)

    c1 = fresh_class.new
    c1.request = ActionDispatch::TestRequest.create
    c1.send(:add_enclosing_resource, forum, :name => 'forum')
    c1.resource = tag
    expect(c1.resource_path).to eq('/forums/1/tags/3')
    expect(c1.enclosing_resource_path(99)).to eq('/forums/99')

    c2 = fresh_class.new
    c2.request = ActionDispatch::TestRequest.create
    c2.send(:add_enclosing_resource, forum, :name => 'forum')
    c2.send(:add_enclosing_resource, post, :name => 'post')
    c2.resource = tag
    expect(c2.resource_path).to eq('/forums/1/posts/2/tags/3')
    expect(c2.enclosing_resource_path).to eq('/forums/1/posts/2')

    c_sub = sub_class.new
    c_sub.request = ActionDispatch::TestRequest.create
    c_sub.send(:add_enclosing_resource, forum, :name => 'forum')
    c_sub.resource = tag

    # After warmup, helpers dispatch to already-defined prefixed methods without hitting method_missing
    expect(c1).not_to receive(:method_missing)
    expect(c2).not_to receive(:method_missing)
    expect(c_sub).not_to receive(:method_missing)
    expect(c1.resource_path(tag)).to eq('/forums/1/tags/3')
    expect(c2.resource_path(99)).to eq('/forums/1/posts/2/tags/99')
    expect(c_sub.resource_path(tag)).to eq('/forums/1/tags/3')

    # Parent adding a new prefix after subclass registered its own prefix still works via fallback
    user = User.new(:id => 4, :login => 'alice')
    address = Address.new(:id => 5)
    c_sub_addr = sub_class.new
    c_sub_addr.request = ActionDispatch::TestRequest.create
    c_sub_addr.send(:add_enclosing_resource, user, :name => 'user')
    c_sub_addr.send(:add_enclosing_resource, address, :name => 'address')
    c_sub_addr.resource = tag
    expect(c_sub_addr.resource_path).to eq('/users/alice/addresses/5/tags/3')

    c_parent_post = fresh_class.new
    c_parent_post.request = ActionDispatch::TestRequest.create
    c_parent_post.send(:add_enclosing_resource, forum, :name => 'forum')
    c_parent_post.send(:add_enclosing_resource, post, :name => 'post')
    c_parent_post.resource = tag
    expect(c_parent_post.resource_path).to eq('/forums/1/posts/2/tags/3')
  end

  it "should preserve eql? semantics when filtering enclosing_collection_resources" do
    fresh_class = Class.new(ApplicationController) do
      resources_controller_for :tags
    end
    eq_only = Class.new do
      def initialize(param)
        @param = param
      end

      def to_param
        @param
      end

      def ==(_other)
        true
      end

      def eql?(other)
        equal?(other)
      end
    end

    first = eq_only.new('1')
    second = eq_only.new('2')
    ctrl = fresh_class.new
    ctrl.request = ActionDispatch::TestRequest.create
    ctrl.send(:add_enclosing_resource, first, :name => 'forum')
    ctrl.send(:add_enclosing_resource, second, :name => 'post')

    # `enclosing_resources_path` (forum_posts_path) has required_args == 1;
    # passing 1 arg filters out only `second` (eql?), leaving `first` intact.
    expect(ctrl.enclosing_resources_path(99)).to eq('/forums/1/posts.99')
  end

  it "should reuse class-level plural_route_name and still honor route_name overrides" do
    expect(@controller.send(:resources_route_name)).to equal(ForumsController.plural_route_name)
    expect(@controller.send(:resources_route_name)).to eq('forums')

    class_override = Class.new(ApplicationController) do
      resources_controller_for :forums
      self.route_name = 'board'
    end
    expect(class_override.new.send(:resources_route_name)).to eq('boards')

    mutated_class = Class.new(ApplicationController) do
      resources_controller_for :forums
    end
    mutated_class.route_name.replace('board')
    expect(mutated_class.new.send(:resources_route_name)).to eq('boards')

    instance_override = Class.new(ApplicationController) do
      resources_controller_for :forums

      def route_name
        'topic'
      end
    end
    expect(instance_override.new.send(:resources_route_name)).to eq('topics')
  end
end
