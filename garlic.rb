garlic do
  repo 'resources_controller', :path => '.'

  repo 'rails', :url => 'git://github.com/rails/rails'
  # using ianwhite/rspec-rails as it has some patches that are not yet applied in dchelimsky/rspec-rails
  repo 'ianwhite-rspec', :url => 'git://github.com/ianwhite/rspec'
  repo 'ianwhite-rspec-rails', :url => 'git://github.com/ianwhite/rspec-rails'

  ['origin/master', 'origin/2-0-stable', 'origin/2-1-stable', 'origin/2-2-stable'].each do |rails|

    target "Rails: #{rails}", :tree_ish => rails do
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
end
