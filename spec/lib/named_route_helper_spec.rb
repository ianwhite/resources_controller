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
end
