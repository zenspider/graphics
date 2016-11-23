#!/usr/local/bin/ruby -w

require "thingy"

class Person < Body
  COUNT = 40

  D_A = 5.0
  D_M = 0.25
  M_M = 5.0

  AA = SDL::Surface::TRANSFORM_AA

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
    trail.draw

    if attack then
      w.angle x, y, a-45, 50, :yellow
      w.angle x, y, a,    60, :red
      w.angle x, y, a+45, 50, :yellow
    end

    w.angle x, y, ga,   60, :red

    # the blit looks HORRIBLE when rotated... dunno why
    w.blit w.body_img, x, y, 0, AA
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
    w.cmap.collision_check(x, y, w.cmap, other.x, other.y) != nil
  end

  def collide
    self.a = (a + 180).degrees
    change_goal
  end
end

class WalkerSimulation < Simulation
  attr_accessor :ps, :body_img, :cmap

  def initialize
    super 850, 850, 16, "Walker"

    self.ps = populate Person

    self.body_img = sprite 20, 20 do
      circle 10, 10, 5, :white, :filled
    end

    self.cmap = body_img.make_collision_map
  end

  def update n
    ps.each(&:update)
    detect_collisions(ps).each(&:collide)
  end

  def draw n
    clear

    ps.each(&:draw)
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
