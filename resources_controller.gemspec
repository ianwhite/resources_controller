# -*- encoding: utf-8 -*-

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require 'resources_controller/version'
version = ResourcesController::VERSION

Gem::Specification.new do |s|
  s.name        = "rc_rails"
  s.version     = version
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ian White"]
  s.email       = "ian.w.white@gmail.com"
  s.homepage    = "http://github.com/ianwhite/resources_controller"
  s.summary     = "resources_controller-#{version}"
  s.description = "rc makes RESTful controllers fun"

  s.rubygems_version   = "1.3.7"

  s.files            = `git ls-files`.split("\n")
  s.test_files       = `git ls-files -- {spec}/*`.split("\n")
  s.extra_rdoc_files = [ "README.rdoc" ]
  s.rdoc_options     = ["--charset=UTF-8"]
  s.require_path     = "lib"

  s.add_runtime_dependency "rails", '>= 3.1.0'
  s.add_development_dependency "rspec", '>= 2.8.0'
  s.add_development_dependency "rspec-rails", '>= 2.8.0'
  s.add_development_dependency 'sqlite3'
end                            