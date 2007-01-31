ENV["RAILS_ENV"] = "test"
require File.expand_path(File.join(File.dirname(__FILE__), "../../../../config/environment.rb"))
require 'spec/rails'

# Even if you're using RSpec, RSpec on Rails is reusing some of the
# Rails-specific extensions for fixtures and stubbed requests, response
# and other things (via RSpec's inherit mechanism). These extensions are 
# tightly coupled to Test::Unit in Rails, which is why you're seeing it here.
module Spec
  module Rails
    class EvalContext < Test::Unit::TestCase
      cattr_accessor :fixture_path, :use_transactional_fixtures, :use_instantiated_fixtures
      self.use_transactional_fixtures = true
      self.use_instantiated_fixtures  = false
      self.fixture_path = File.join(File.dirname(__FILE__), 'fixtures')

      # You can set up your global fixtures here, or you
      # can do it in individual contexts
      #fixtures :table_a, :table_b
    end
  end
end


# Testing app setup

class Forum < ActiveRecord::Base
  has_many :posts
end

class Post < ActiveRecord::Base
  belongs_to :forum
  has_many :comments
end

class Comment < ActiveRecord::Base
  belongs_to :post
end

class ForumsController < ActionController::Base
  resources_controller_for :forums
end

class ForumPostsController < ActionController::Base
  resources_controller_for :posts
  nested_in :forum
  
  def whatever; end
end

class CommentsController < ActionController::Base
  resources_controller_for :comments, :in => [:forum, :post]

  def whatever; end
end

ActionController::Routing::Routes.draw do |map|
  map.resources :forums do |forums|
    forums.resources :posts, :name_prefix => 'forum_', :controller => 'forum_posts', :collection => {:whatever => :get} do |posts|
      posts.resources :comments, :collection => {:whatever => :get}
    end
  end
end
