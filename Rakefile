# -*- ruby -*-

require "rubygems"
require "hoe"

Hoe.plugin :isolate
Hoe.plugin :seattlerb
Hoe.plugins.delete :perforce
Hoe.plugin :rdoc
Hoe.plugin :git

Hoe.spec "graphics" do
  developer "Ryan Davis", "ryand-ruby@zenspider.com"
  license "MIT"

  dependency "rsdl", "~> 0.1"
  dependency "rubysdl", "~> 2.2"
end

task :demos do
  Dir["examples/*.rb"].each do |script|
    puts script
    system "rsdl -Ilib #{script}"
  end
end

# vim: syntax=ruby
