require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '../app'))

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
end