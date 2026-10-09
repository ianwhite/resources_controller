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
end
