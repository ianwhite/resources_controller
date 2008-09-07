namespace :spec do
  desc "Run rspec's generated specs against RC'd controllers"
  task :generate do
    RAILS_ROOT = File.expand_path("../../..") # relative to the rc Rakefile
    require_activesupport
    
    cd RAILS_ROOT do
      begin
        generate_resource :author
        sh "rake db:migrate"
        make_resources_controller :author
        sh "rake spec:controllers"
      ensure
        sh "rake db:migrate VERSION=0"
        cleanup_resource :author
      end
    end
  end
  
  def require_activesupport
    begin
      require File.join(RAILS_ROOT, 'vendor/rails/activesupport/lib/activesupport')
    rescue Exception
      require 'activesupport'
    end
  end
  
  def generate_resource(name)
    sh "script/generate rspec_scaffold #{name.to_s.classify}"
  end
  
  def make_resources_controller(name)
    plural = name.to_s.pluralize
    File.open("app/controllers/#{plural}_controller.rb", "w+") do |f|
      f << <<-end_eval
class #{plural.classify.pluralize}Controller < ApplicationController
  resources_controller_for :#{plural}
end
      end_eval
    end
    puts File.read("app/controllers/#{plural}_controller.rb")
  end
  
  def cleanup_resource(name)
    puts "Cleaning up files for resource: #{name}"
    plural = name.to_s.pluralize

    # remove app files
    rm "app/models/#{name}.rb"
    rm "app/controllers/#{plural}_controller.rb"
    rm "app/helpers/#{plural}_helper.rb"
    rm_rf "app/views/#{plural}"

    # remove migration
    rm Dir["db/migrate/*_create_#{plural}.rb"]

    # revert routes
    routes_rb = File.read("config/routes.rb")
    routes_rb.sub!("\n  map.resources :#{plural}\n", '')
    File.open("config/routes.rb", "w+") {|f| f << routes_rb}

    # remove spec files
    rm "spec/models/#{name}_spec.rb"
    rm "spec/fixtures/#{plural}.yml"
    rm Dir["spec/controllers/#{plural}*_spec.rb"]
    rm "spec/helpers/#{plural}_helper_spec.rb"
    rm_rf "spec/views/#{plural}"
  end
end