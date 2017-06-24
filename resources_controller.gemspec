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

  s.rubygems_version   = "2.0.3"

  s.files            = `git ls-files`.split("\n")
  s.test_files       = `git ls-files -- {spec}/*`.split("\n")
  s.extra_rdoc_files = [ "README.rdoc" ]
  s.rdoc_options     = ["--charset=UTF-8"]
  s.require_path     = "lib"

  s.add_runtime_dependency "rails", '>= 5.1.1'
  s.add_development_dependency "rspec", '>= 3'
  s.add_development_dependency "rspec-rails", '>= 3.5'
  s.add_development_dependency 'rails-controller-testing'
  s.add_development_dependency 'rspec-activemodel-mocks'
  s.add_development_dependency 'activemodel-serializers-xml'
  s.add_development_dependency 'sqlite3'
end                            
