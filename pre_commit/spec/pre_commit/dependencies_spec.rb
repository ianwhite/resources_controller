require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))

describe PreCommit::Dependency do
  describe ".new(:type => :file, :path => 'foo')" do
    it "should call PreCommit::FileDependency.new(:path => 'foo')" do
      PreCommit::FileDependency.should_receive(:new).with(:path => 'foo')
      PreCommit::Dependency.new(:type => :file, :path => 'foo')
    end
  end
end