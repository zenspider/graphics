#!/usr/local/bin/ruby -w
# -*- coding: utf-8 -*-

require "graphics"

class Demo < Graphics::Simulation
  CLEAR_COLOR = :white

  attr_accessor :woot, :big_font
  attr_accessor :rct

  def initialize
    super 801, 801

    self.font = find_font(DEFAULT_FONT, 16)
    self.big_font = find_font(DEFAULT_FONT, 32)

    self.woot = render_text "woot", :black, big_font

    self.rct = sprite 50, 25 do
      rect 0, 0, 49, 24, :blue # TODO: can't be black?!?
    end
  end

  def update n
  end

  L = Math.sqrt(200*200 + 100*100)
  A = R2D*Math.atan2(200, 100)

  def draw n
    clear

    (0..90).step(30) do |deg|
      shift = (woot.h*Math.sin(D2R*deg))
      put woot, 400-shift, 300, deg
    end
    text "woot", 400, 300, :red, big_font

    rect 550, 100, 50, 50, :blue, :filled
    rect 575, 125, 50, 50, :blue

    ellipse 550, 200, 50, 25, :red
    ellipse 550, 250, 50, 25, :red, :filled

    angle 50, 50, 90, 25, :blue

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

    bezier 400, 400, 450, 700, 550, 300, 600, 600, :blue
    text "bezier 400, 400, 450, 700, 550, 300, 600, 600, :blue", 200, 400, :black

    angle 200, 500, A, L, :black
    text "angle 200, 500, %.2f, %.2f, :black" % [A, L], 100, 500, :black

    (0..90).step(30).each do |deg|
      put rct, 500-(rct.h*Math.sin(D2R*deg)), 600, deg
      angle 500, 600, deg, 50, :red

      blit rct, 600, 600, deg
      angle 600, 600, deg, 50, :red
    end
  end
end

Demo.new.run if $0 == __FILE__
