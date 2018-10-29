#!/usr/local/bin/ruby -w

require "graphics"
require "graphics/trail"

class Person < Graphics::Body
  COUNT = 40

  D_A = 5.0
  D_M = 0.25
  M_M = 5.0

  attr_accessor :trail

  def initialize w
    super

    self.trail = Graphics::Trail.new w, 100, :green

    self.a  = random_angle
    self.ga = random_angle
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

  def turn_towards_goal
    turn a.relative_angle(ga, D_A)
  end

  def change_goal
    self.ga = a + random_turn(180)
  end

  def possibly_change_goal
    change_goal if ga.close_to?(a) && 1 =~ 25
  end

  def collide_with? other
    w.cmap.check(x, y, w.cmap, other.x, other.y) != nil
  end

  def collide
    self.a = (a + 180).degrees
    change_goal
  end

  class View
    def self.draw w, b
      b.trail.draw

      w.angle b.x, b.y, b.ga, 60, :red

      # the blit looks HORRIBLE when rotated... dunno why
      w.blit w.body_img, b.x, b.y
    end
  end
end

class WalkerSimulation < Graphics::Simulation
  attr_accessor :ps, :body_img, :cmap

  def initialize
    super 850, 850

    self.ps = populate Person
    register_bodies ps

    self.body_img = sprite 20, 20 do
      circle 10, 10, 5, :white, :filled
    end

    self.cmap = body_img.make_collision_map
  end

  def update n
    super

    detect_collisions(ps).each(&:collide)
  end

  def draw n
    super

    fps n
  end

  def detect_collisions sprites
    collisions = []
    sprites.combination(2).each do |a, b|
      collisions << a << b if a.collide_with? b
    end
    collisions.uniq
  end
end

WalkerSimulation.new.run
