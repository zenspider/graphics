#!/usr/local/bin/ruby -w
# -*- coding: utf-8 -*-

require "graphics"

class Ball < Graphics::Body
  def initialize w
    super

    self.x = 50
    self.y = 50

    self.a = 60
    self.m = 3
  end

  def update
    move
    wrap
  end

  class View
    def self.draw w, b
      a = w.n % 360
      x, y = b.x, b.y

      w.angle  x, y, a, 50,     :green
      w.circle x, y, 5, :white, :filled
    end
  end
end

class Demo < Graphics::Simulation
  attr_accessor :ball, :img, :n

  def initialize
    super 800, 800
    self.ball = Ball.new self
    register_body ball

    self.img = sprite 10, 10 do
      circle 5, 5, 5, :white, :filled
    end
  end

  def draw n
    self.n = n

    super

    line 100, 50, 125, 75, :white

    hline 100, :white

    vline 100, :white

    angle 125, 50, 45, 10, :white

    fast_rect 150, 50, 10, 10, :white

    point 175, 50, :green

    rect 200, 50, 10, 10, :white

    circle 225, 50, 10, :white

    ellipse 250, 50, 10, 20, :white

    bezier 275, 50, 275, 100, 285, 0, 300, 50, :white

    rect 300, 25, 50, 50, :white

    blit img, 325, 50 # centered
    put img, 335, 50  # cornered

    text "blah", 350, 50, :white

    x, y, * = mouse
    rect x, y, 150, 50, :white
    text "#{x}/#{y}", x, y, :white

    debug "debug"

    fps n
  end
end

Demo.new.run if $0 == __FILE__
