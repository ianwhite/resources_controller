require 'file_utils'

include FileUtils

cd RAILS_ROOT do
  `rake db:migrate VERSION=0`
  `script/generate rspec_scaffold Author`
  `rake db:migrate`
  system "rake spec"
end