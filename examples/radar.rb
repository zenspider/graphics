#!/usr/bin/ruby -w

require "graphics"

class Radar < Graphics::Simulation
  CLEAR_COLOR = :darker_green

  def initialize
    super 640, 640

    register_color :darker_green,  0, 16,  0
    register_color :dark_green,   64, 96, 64
    register_color :dark_blue,     0,  0, 96
  end

  def draw n
    clear

    (0..640).step(64).each do |r|
      hline r, :dark_green
      vline r, :dark_green
      circle 320, 320, r, :dark_green unless r > 320
    end

    x, y, * = mouse
    line x, 0, x, 640, :white
    line 0, y, 640, y, :white

    fps n
  end
end

Radar.new.run
