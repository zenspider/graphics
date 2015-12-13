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
    self.s = w.screen
    self.a = random_angle
    self.m = M

    self.white = w.color[:white]
    self.black = w.color[:black]
  end

  def forward
    move
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

class Vants < Graphics::Simulation
  attr_accessor :vs

  def initialize
    super 850, 850, 16, self.class.name

    # cheat and reopen screen w/o double buffering
    self.screen = SDL::Screen.open 850, 850, 16, SDL::HWSURFACE
    clear :white

    self.vs = populate Vant
  end

  def update n
    vs.each(&:forward)
  end

  def draw_and_flip n
    self.draw n
    # no flip
  end

  def draw n
    screen.update 0, 0, 0, 0
  end
end

Vants.new.run if $0 == __FILE__
