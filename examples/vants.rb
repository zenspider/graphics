#!/usr/local/bin/ruby -w
# -*- coding: utf-8 -*-

srand 42

require "graphics"

##
# Virtual Ants -- inspired by a model in NetLogo.

class Vant < Graphics::Body
  COUNT = 100
  M = 1

  attr_accessor :white, :black, :red, :s

  def initialize w
    super
    self.a = random_angle
    self.s = w.screen

    self.white = w.color[:white]
    self.black = w.color[:black]
  end

  def update
    move_by a, M
    mutate
  end

  def mutate
    if s[x, y] == white then
      s[x, y] = black
      turn 270
    else
      s[x, y] = white
      turn 90
    end
  end
end

class Vants < Graphics::Drawing
  attr_accessor :vs

  CLEAR_COLOR = :white

  def initialize
    super 850, 850, 16, self.class.name

    self.vs = populate Vant
    register_bodies vs
  end
end

Vants.new.run if $0 == __FILE__
