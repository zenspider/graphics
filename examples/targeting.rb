#!/usr/bin/ruby -w

require "graphics"

class Targeting < Graphics::Simulation
  CLEAR_COLOR = :darker_green

  attr_accessor :bombs

  def initialize
    super 640, 640

    self.bombs = []
    register_color :darker_green,  0, 16,  0
    register_color :dark_green,   64, 96, 64
    register_color :dark_blue,     0,  0, 96
  end

  def handle_event event, n
    bombs << [n, event.x, h-event.y] if SDL::Event::Mousedown === event
    super
  end

  def draw n
    clear

    bombs.each do |(birth, bx, by)|
      r = n - birth
      r = [r, 100].min
      circle bx, by, r, :dark_blue, :fill
      circle bx, by, r, :red unless r == 100
    end

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

Targeting.new.run
