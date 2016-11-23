#!/usr/local/bin/ruby -w

require "thingy"

class Sprite < Body
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

  def draw
    w.blit image, x, y, a
  end

  def collide_with? other
    w.cmap.collision_check(x, y, w.cmap, other.x, other.y) != nil
  end
end

class Collision < Thingy
  attr_accessor :sprites, :cmap, :image

  def initialize
    super 850, 850, 16, "Collision"

    self.image = SDL::Surface.load "resources/images/body.png"
    self.cmap = image.make_collision_map

    self.sprites = populate Sprite do |s|
      s.image = image
    end
  end

  def inspect
    "<Screen ...>"
  end

  def detect_collisions(sprites)
    collisions = []
    sprites.combination(2).each do |a, b|
      collisions << a << b if a.collide_with? b
    end
    collisions.uniq
  end

  def update n
    sprites.each(&:update)
    detect_collisions(sprites).each(&:collide)
  end

  def draw n
    clear

    sprites.each(&:draw)
    fps n
  end
end

Collision.new.run
