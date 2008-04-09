require File.expand_path(File.join(File.dirname(__FILE__), 'pre_commit/lib/pre_commit'))
include PreCommit::Support

task :cruise do
  puts rake_sh(:cruise, '-f', 'pre_commit.rake', :in => 'example_app')
end