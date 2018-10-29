# -*- ruby -*-

require "rubygems"
require "hoe"

Hoe.plugin :isolate
Hoe.plugin :seattlerb
Hoe.plugin :rdoc
Hoe.plugin :git
Hoe.plugin :compiler

Hoe.add_include_dirs File.expand_path "~/Work/p4/zss/src/minitest/dev/lib"

Hoe.spec "graphics" do
  developer "Ryan Davis", "ryand-ruby@zenspider.com"

  extension :sdl

  license "MIT"
end

task :demos => :compile do
  Dir["examples/*.rb"].sort.each do |script|
    puts script
    system "ruby -Ilib #{script}"
  end
end

task :sanity => :compile do
  sh %[ruby -Ilib -rgraphics -e 'Class.new(Graphics::Simulation) { def draw n; clear :white; text "hit escape to quit", 100, 100, :black; end; }.new(500, 250, "Working!").run']
end

# vim: syntax=ruby
