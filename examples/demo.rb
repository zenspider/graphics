#!/usr/local/bin/ruby -w
# -*- coding: utf-8 -*-

require "graphics"

class Ball < Graphics::Body
  def initialize e
    super e

    self.x = self.y = 50
    self.a = 60
    self.m = 3
  end

  def update
    move
    wrap
  end

  class View
    def self.draw w, o
      w.angle  o.x, o.y, o.env.n % 360, 50, :green
      w.circle o.x, o.y, 5, :white, :filled

      w.fps o.env.n, o.env.start_time
      w.debug "debug"
    end
  end
end

class StaticStuff < Graphics::Body
  class View
    def self.draw w, o
      w.line 100, 50, 125, 75, :white

      w.hline 100, :white

      w.vline 100, :white

      w.angle 125, 50, 45, 10, :white

      w.fast_rect 150, 50, 10, 10, :white

      w.point 175, 50, :green

      w.rect 200, 50, 10, 10, :white

      w.circle 225, 50, 10, :white

      w.ellipse 250, 50, 10, 20, :white

      w.bezier 275, 50, 275, 100, 285, 0, 300, 50, :white

      w.text "blah", 350, 50, :white

      x_m, y_m, * = w.mouse
      w.rect x_m, y_m, 150, 50, :white
      w.text "#{x_m}/#{y_m}", x_m, y_m, :white
    end
  end
end

class BlitiThing < Graphics::Body
  attr_accessor :img

  def initialize e, img
    super e
    self.img = img
    self.x = 325
    self.y = 50
  end

  class View
    def self.draw w, o
      w.rect 300, 25, 50, 50, :white
      w.blit o.img, o.x,    o.y # centered
      w.put  o.img, o.x+10, o.y # cornered
    end
  end
end

class Demo < Graphics::Simulation
  attr_accessor :ball, :img

  def initialize
    super 800, 800, 16, "Boid"

    blip = canvas.sprite 11, 11 do
      canvas.circle 5, 5, 5, :white, :filled
    end

    env._bodies << [Ball.new(self.env)]           \
                << [StaticStuff.new(self.env)]    \
                << [BlitiThing.new(self.env, blip)]
  end
end

Demo.new.run if $0 == __FILE__
