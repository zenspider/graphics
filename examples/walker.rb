#!/usr/local/bin/ruby -w

# srand 42

require "thingy"

class Person < Body
  COUNT = 25

  D_A = 2.0
  D_M = 0.25
  M_M = 5.0

  attr_accessor :trail, :attack

  def initialize w
    super

    self.trail = Trail.new w, 100, :green

    self.a  = random_angle
    self.ga = random_angle
    self.attack = false
  end

  def update
    turn_towards_goal
    possibly_change_goal

    accelerate
    move

    trail << self

    clip_off_wall
  end

  def accelerate
    self.m += D_M unless m >= M_M
  end

  def draw
    w.angle x, y, ga,   60, :blue

    if attack then
      w.angle x, y, a-45, 50, :yellow
      w.angle x, y, a,    60, :red
      w.angle x, y, a+45, 50, :yellow
    end

    w.circle x, y, 5, :white, :filled

    trail.draw
  end

  def turn_towards_goal
    turn a.relative_angle(ga, D_A)
  end

  def possibly_change_goal
    self.ga = 360 * rand if ga.close_to?(a) && 1 =~ 50
  end
end

class WalkerThingy < Thingy
  attr_accessor :ps

  N = 10

  def initialize
    super 850, 850, 16, "Walker"

    self.ps = populate Person, Person::COUNT
  end

  def update n
    ps.each(&:update)
  end

  def draw n
    clear

    ps.each(&:draw)
  end
end

WalkerThingy.new.run
