# -*- encoding: utf-8 -*-

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require 'resources_controller/version'
version = ResourcesController::VERSION

Gem::Specification.new do |s|
  s.name        = "rc_rails"
  s.version     = version
  s.platform    = Gem::Platform::RUBY
  s.required_ruby_version = '>= 3.3'
  s.authors     = ["Ian White"]
  s.email       = "ian.w.white@gmail.com"
  s.homepage    = "http://github.com/ianwhite/resources_controller"
  s.summary     = "resources_controller-#{version}"
  s.description = "rc makes RESTful controllers fun"
  s.license     = "MIT"

  s.files            = Dir["lib/**/*.rb", "CHANGELOG", "MIT-LICENSE", "README.md"]
  s.extra_rdoc_files = [ "README.md" ]
  s.rdoc_options     = ["--charset=UTF-8"]
  s.require_path     = "lib"

  s.metadata = {
    "source_code_uri"       => "https://github.com/ianwhite/resources_controller",
    "changelog_uri"         => "https://github.com/ianwhite/resources_controller/blob/master/CHANGELOG",
    "bug_tracker_uri"       => "https://github.com/ianwhite/resources_controller/issues",
    "rubygems_mfa_required" => "true"
  }

  s.add_runtime_dependency "rails", '>= 8.0'
  s.add_development_dependency "rspec", '>= 3'
  s.add_development_dependency "rspec-rails", '>= 3.5'
  s.add_development_dependency 'rails-controller-testing'
  s.add_development_dependency 'rspec-activemodel-mocks'
  s.add_development_dependency 'sqlite3'
end                            
