garlic do
  repo 'resources_controller', :path => '.'
  repo 'rails', :url => 'git://github.com/rails/rails'
  repo 'rspec', :url => 'git://github.com/dchelimsky/rspec'
  repo 'rspec-rails', :url => 'git://github.com/dchelimsky/rspec-rails'

  ['origin/2-1-stable', 'origin/2-2-stable'].each do |rails|

    target "Rails: #{rails}", :tree_ish => rails do
      prepare do
        plugin 'resources_controller', :clone => true
        plugin 'rspec', :as => 'rspec'
        plugin 'rspec-rails', :as => 'rspec-rails' do
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
