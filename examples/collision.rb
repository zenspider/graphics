#!/usr/local/bin/ruby -w

# require "graphics"
require "/Users/fjs6/work/graphics_code/graphics/lib/graphics"

class Tank < Graphics::Body
  COUNT = 8

  attr_accessor :sprite, :cmap, :updated

  def initialize e
    super e

    self.a = random_angle
    self.m = 5
    self.updated = false
  end

  def spritify img
    self.sprite = img
    self.cmap = img.make_collision_map
  end

  def update
    move(&:bounce)
    self.updated = false
  end

  def detect
    if !self.updated
      crashing = env._bodies.flatten.select { |t| collide_with? t }

      crashing.each(&:veer) if crashing.size > 1
    end
  end

  def veer
    turn 180
    self.updated = false
  end

  def collide_with? other
    self.cmap.check self.endpoint.x, self.endpoint.y,  \
                    other.cmap,                        \
                    other.endpoint.x, other.endpoint.y
  end

  class View
    def self.draw w, o
      w.blit o.sprite, o.x, o.y, o.a
      w.fps o.env.n, o.env.start_time
    end
  end
end

class Collision < Graphics::Simulation
  def initialize
    super 800, 800, 16, "Collision"

    tank_img = image "resources/images/body.png"

    register_bodies  populate(Tank) { |b| b.spritify tank_img }
  end

  def update n
    env.n = n
    env._bodies.each { |ary| ary.each(&:detect) }
               .each { |ary| ary.each(&:update) }
  end

  def inspect
    "<Screen ...>"
  end
end

Collision.new.run
