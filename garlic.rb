garlic do
  repo 'resources_controller', :path => '.'

  repo 'rails', :url => 'git://github.com/rails/rails'#, :local => "~/dev/vendor/rails"

  # using ianwhite/rspec-rails as it has some patches that are not yet applied in dchelimsky/rspec-rails
  repo 'ianwhite-rspec', :url => 'git://github.com/ianwhite/rspec'
  repo 'ianwhite-rspec-rails', :url => 'git://github.com/ianwhite/rspec-rails'

  #target 'edge'
  target '2.0-stable', :branch => 'origin/2-0-stable'
  target '2.1-stable', :branch => 'origin/2-1-stable'
  target '2.2-stable', :branch => 'origin/2-2-stable'

  all_targets do
    prepare do
      plugin 'resources_controller', :clone => true
      plugin 'ianwhite-rspec', :as => 'rspec'
      plugin 'ianwhite-rspec-rails', :as => 'rspec-rails' do
        sh "script/generate rspec -f"
      end
    end
  
    run do
      cd "vendor/plugins/resources_controller" do
        sh "rake spec:rcov:verify && rake spec:generate"
      end
    end
  end
end
