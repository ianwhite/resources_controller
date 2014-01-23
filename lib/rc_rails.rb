require 'resources_controller'

# BC
module Ardes
  ResourcesController = ::ResourcesController
  module ActiveRecord
    Saved = ::ResourcesController::ActiveRecord::Saved
  end
end