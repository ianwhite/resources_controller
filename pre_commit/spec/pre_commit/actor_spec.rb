require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))

class ActorExampleClass
  include PreCommit::Actor
end

describe "class with PreCommit::Actor" do
  before do
    @actor = mock('rake instance')
    @object = ActorExampleClass.new
    @object.actor = @actor
  end
  
  it "should have actor == object passed at initialization" do
    @object.actor.should == @actor
  end
  
  it "should delegate unknown method to actor" do
    @actor.should_receive(:crickey)
    @object.crickey
  end
end