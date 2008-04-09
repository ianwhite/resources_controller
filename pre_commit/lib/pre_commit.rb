$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__)))

require 'rubygems'
require 'active_support'

require "pre_commit/actor"
require "pre_commit/support"
require "pre_commit/dependencies"
require "pre_commit/base"
require "pre_commit/svn"
require "pre_commit/rails"