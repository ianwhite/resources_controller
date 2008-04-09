desc "Run pre_commit (makes sure it's ok to commit)"
task :pre_commit => 'dependencies:verify' do
  pre_commit.pre_commit
end

namespace :dependencies do
  desc "Check that dependencies are installed properly"
  task :verify do
    pre_commit.dependencies.verify
  end

  desc "Install all dependencies"
  task :install do
    pre_commit.dependencies.install
  end

  desc "Update all dependencies"
  task :update => :verify do
    pre_commit.dependencies.update 
  end

  desc "Remove all local dependencies"
  task :clobber do
    pre_commit.dependencies.clobber
  end
end

desc "cruise: continuous integration task"
task :cruise => ['dependencies:install', 'dependencies:update', 'pre_commit']

task :clobber_files do
  pre_commit.clobber_using_svn
end

task :install_db_config do
  pre_commit.install_db_config
end