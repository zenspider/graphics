#!/usr/local/bin/ruby -w
# -*- coding: utf-8 -*-

require "graphics"

class Demo < Graphics::Simulation
  def initialize
    super 801, 801

    self.font = find_font("Menlo", 16)
  end

  sys_font  = "/System/Library/Fonts"
  lib_font  = "/Library/Fonts"
  user_font = File.expand_path "~/Library/Fonts/"
  FONT_GLOB = "{#{sys_font},#{lib_font},#{user_font}}"

  def find_font name, size = 16
    font = Dir["#{FONT_GLOB}/#{name}.{ttc,ttf}"].first

    raise ArgumentError, "Can't find font named '#{name}'" unless font

    SDL::TTF.open(font, size)
  end

  def update n
  end

  def draw n
    clear :white

    (0..w).step(100) do |x|
      vline x, :red
      text x.to_s, x+5, 5, :black
    end

    (0..h).step(100) do |y|
      hline y, :green
      text y.to_s, 5, y+5, :black
    end

    circle 200, 200, 100, :blue
    text "circle 200, 200, 100, :blue", 100, 200, :black

    bezier 400, 400, 450, 700, 550, 350, 600, 600, :blue
    text "bezier 400, 400, 450, 700, 550, 350, 600, 600, :blue", 200, 400, :black
  end
end

Demo.new.run if $0 == __FILE__
