require 'rubygems'

Gem::manage_gems

require 'rake/rdoctask'
require 'spec/rake/spectask'

plugin_name = File.basename(File.dirname(__FILE__))

desc "Default: run the specs for #{plugin_name}"
task :default => :rspec

desc "Run the specs for #{plugin_name}"
Spec::Rake::SpecTask.new(:rspec) do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.spec_opts  = ["--colour"]
end

desc "Generate RCov report for #{plugin_name} "
Spec::Rake::SpecTask.new(:rcov) do |t|
  t.spec_files  = FileList['spec/**/*_spec.rb']
  t.rcov        = true
  t.rcov_dir    = 'doc/coverage'
  t.rcov_opts   = ['--exclude', 'config\/,spec\/,\/app\/']
end

desc "Generate RDoc specdoc for #{plugin_name}"
Spec::Rake::SpecTask.new(:rspec_rdoc) do |t|
  t.spec_files  = FileList['spec/**/*_spec.rb']
  t.spec_opts   = ["--format", "rdoc"]
  t.out         = 'SPECDOC'
end

desc "Generate RSpec html report for #{plugin_name}"
Spec::Rake::SpecTask.new(:rspec_rep) do |t|
  t.spec_files    = FileList['spec/**/*_spec.rb']
  t.spec_opts     = ["--format", "html", "--diff"]
  t.out           = 'doc/rspec_report.html'
  t.fail_on_error = false
end

desc "Generate documentation for #{plugin_name}"
task :rdoc => :rspec_rdoc
Rake::RDocTask.new(:rdoc) do |t|
  t.rdoc_dir = 'doc'
  t.main     = 'README'
  t.title    = "#{plugin_name}"
  t.options  = ['--line-numbers', '--inline-source']
  t.rdoc_files.include('README', 'SPECDOC', 'MIT-LICENSE')
  t.rdoc_files.include('lib/**/*.rb')
end

desc "Generate all documentation for the #{plugin_name} plugin."
task :rdoc_all => :rdoc
task :rdoc_all => :rspec_rep
task :rdoc_all => :rcov
