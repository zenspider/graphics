#!/usr/local/bin/ruby -w

require "graphics"

class Sprite < Graphics::Body
  COUNT = 8

  attr_accessor :image

  def initialize w
    super w

    self.a = random_angle
    self.m = 5
  end

  def update
    move
    bounce
  end

  def collide
    self.a = (a + 180).degrees
  end

  def collide_with? other
    w.cmap.check(x, y, w.cmap, other.x, other.y)
  end

  class View
    def self.draw w, b
      w.blit b.image, b.x, b.y, b.a
    end
  end
end

class Collision < Graphics::Simulation
  attr_accessor :sprites, :cmap, :tank_img

  def initialize
    super 850, 850

    self.tank_img = image "resources/images/body.png"
    self.cmap = tank_img.make_collision_map

    self.sprites = populate Sprite do |s|
      s.image = tank_img
    end

    register_bodies sprites
  end

  def inspect
    "<Screen ...>"
  end

  def detect_collisions sprites
    collisions = []
    sprites.combination(2).each do |a, b|
      collisions << a << b if a.collide_with? b
    end
    collisions.uniq
  end

  def update n
    super
    detect_collisions(sprites).each(&:collide)
  end

  def draw n
    super
    fps n
  end
end

Collision.new.run
