require 'rspec/core/rake_task'
require 'spec/verify_rcov' # a local file future-ported from RSpec 1.x

task :default => :spec

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'spec/**/*_spec.rb'
  t.spec_opts  = ["--colour"]
end

RSpec::Core::RakeTask.new(:rcov) do |t|
  t.pattern  = 'spec/**/*_spec.rb'
  t.rcov        = true
  t.rcov_opts   = ['--output', 'doc/coverage','--text-report', '--exclude', "gems/,spec/,rcov.rb,#{File.expand_path(File.join(File.dirname(__FILE__),'../../..'))}"] 
end

namespace :rcov do
  RCov::VerifyTask.new(:verify => :rcov) do |t|
    t.threshold = 100.0
    t.index_html = File.join(File.dirname(__FILE__), 'doc/coverage/index.html')
  end
end

# load up the tasks for testing rspec generators against RC
require 'spec/rspec_generator_task'