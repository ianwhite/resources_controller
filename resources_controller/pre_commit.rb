# this file is included by a pre_commit.rake file
class PreCommit::ResourcesController < PreCommit::Base
  include PreCommit::Rails
  
  self.dependencies = [
    { :type => :rails, :name => "Edge Rails", :path => "vendor/railses/edge", :url => "http://svn.rubyonrails.org/rails/trunk" , :tagged? => false },
    { :type => :rails, :name => "Rails 2.0.2", :path => "vendor/railses/2.0.2", :url => "http://dev.rubyonrails.org/svn/rails/tags/rel_2-0-2", :tagged? => true },
    { :type => :svn, :name => "Rspec", :path => "vendor/plugins/rspec", :url => "http://rspec.rubyforge.org/svn/trunk/rspec", :tagged? => false },
    { :type => :svn, :name => "Rspec on Rails", :path => "vendor/plugins/rspec_on_rails", :url => "http://rspec.rubyforge.org/svn/trunk/rspec_on_rails", :tagged? => false },
    { :type => :file, :name => "Resources Controller", :path => 'vendor/plugins/resources_controller', :src => '../resources_controller' }
  ]
  
  def pre_commit
    with_railses "pre_commit" do
      rc_cruise
    end
  end
  
  def rc_cruise
    puts "Running plugin cruise task"
    puts rake_sh('cruise', :in => "vendor/plugins/resources_controller", :RAILS_ENV => 'test')
    puts
  end
end
