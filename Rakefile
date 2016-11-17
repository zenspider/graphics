# -*- ruby -*-

require "rubygems"
require "hoe"

Hoe.plugin :isolate
Hoe.plugin :minitest, :history, :email # Hoe.plugin :seattlerb - :perforce
Hoe.plugin :rdoc
Hoe.plugin :git
Hoe.plugin :compiler

Hoe.add_include_dirs File.expand_path "~/Work/p4/zss/src/minitest/dev/lib"

Hoe.spec "graphics" do
  developer "Ryan Davis", "ryand-ruby@zenspider.com"

  extension :sdl

  license "MIT"

  dependency "rsdl", "~> 0.1"

  base = "/data/www/docs.seattlerb.org"
  rdoc_locations << "docs-push.seattlerb.org:#{base}/#{remote_rdoc_dir}"
end

task :demos => :compile do
  Dir["examples/*.rb"].each do |script|
    puts script
    system "rsdl -Ilib #{script}"
  end
end

# vim: syntax=ruby
