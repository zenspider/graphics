# -*- ruby -*-

require "rubygems"
require "hoe"

Hoe.plugin :isolate
Hoe.plugin :minitest, :history, :email # Hoe.plugin :seattlerb - :perforce
Hoe.plugin :rdoc
Hoe.plugin :git

Hoe.spec "graphics" do
  developer "Ryan Davis", "ryand-ruby@zenspider.com"
  license "MIT"

  dependency "rsdl", "~> 0.1"
  dependency "rubysdl", "~> 2.2"

  base = "/data/www/docs.seattlerb.org"
  rdoc_locations << "docs-push.seattlerb.org:#{base}/#{remote_rdoc_dir}"
end

task :demos do
  Dir["examples/*.rb"].each do |script|
    puts script
    system "rsdl -Ilib #{script}"
  end
end

# vim: syntax=ruby
