#!/usr/bin/ruby -w

require "graphics"

D2R = Math::PI / 180.0

class Tank
  ACCELERATE   = 0.25
  DECELERATE   = 0.125
  ROTATION     = 2
  TICK_ENERGY  = 5
  SHOT_ENERGY  = 100

  MAX_SPEED    = 4.0
  MAX_ROTATION = 360
  MAX_ENERGY   = 100

  attr_accessor :angle, :speed, :x, :y, :sim
  attr_accessor :turret, :energy

  def initialize x, y
    self.x      = x
    self.y      = y
    self.angle  = 0
    self.turret = 0
    self.speed  = 0
    self.energy = 0
  end

  def update
    rad = angle * D2R

    self.x += Math.cos(rad) * speed
    self.y += Math.sin(rad) * speed

    self.energy += TICK_ENERGY

    limit
  end

  def limit
    self.angle  %= MAX_ROTATION
    self.turret %= MAX_ROTATION
    self.energy = MAX_ENERGY if energy > MAX_ENERGY

    if speed > MAX_SPEED then
      self.speed = MAX_SPEED
    elsif speed < 0 then
      self.speed = 0
    end
  end

  def fire
    rad = turret * D2R
    x2 = x + Math.cos(rad) * 20
    y2 = y + Math.sin(rad) * 20

    if energy >= SHOT_ENERGY then
      self.energy -= SHOT_ENERGY
      Bullet.new x2, y2, turret, speed
    end
  end

  def turn_right; self.angle -= ROTATION; aim_right; end
  def turn_left;  self.angle += ROTATION; aim_left;  end

  def aim_right;  self.turret -= ROTATION; end
  def aim_left;   self.turret += ROTATION; end

  def accelerate; self.speed += ACCELERATE; end
  def decelerate; self.speed -= DECELERATE; end

  class View
    def self.draw w, b
      x, y, a, t = b.x, b.y, b.angle, b.turret

      w.blit w.body_img, x, y, a
      w.blit w.turret_img, x, y, t

      w.debug "%3d @ %.2f @ %d", a, b.speed, b.energy
    end
  end
end

class Bullet
  attr_accessor :x, :y, :a, :v

  def initialize x, y, a, v
    self.x = x
    self.y = y
    self.a = a
    self.v = v + 5
  end

  def update
    rad = a * D2R

    self.x += Math.cos(rad) * v
    self.y += Math.sin(rad) * v
  end

  class View
    def self.draw w, b
      w.rect b.x, b.y, 2, 2, :white
    end
  end
end

class TankSprites < Graphics::Simulation
  attr_accessor :tank, :bullets
  attr_accessor :body_img
  attr_accessor :turret_img

  def initialize
    super 640, 640

    self.tank = Tank.new w/2, h/2
    self.bullets = []

    register_body tank
    register_bodies bullets

    self.body_img = sprite 40, 30 do
      rect 0,  0, 39, 29, :white
      rect 0,  4, 39, 21, :white

      line 0,  2, 39,  2, :white
      line 0, 27, 39, 27, :white
    end

    a, b = 41, 16
    self.turret_img = sprite a, b do
      rect a/2-8, b/2-8, 15, 15, :white
      angle a/2, b/2, 0, 28, :white
      line a/2+20, b/2-2, a/2+20, b/2+2, :white
    end
  end

  def initialize_keys
    super

    keydown_handler.delete "q"  # HACK

    add_key_handler(:RIGHT)     { tank.turn_right }
    add_key_handler(:LEFT)      { tank.turn_left }
    add_key_handler(:UP)        { tank.accelerate }
    add_key_handler(:DOWN)      { tank.decelerate }
    add_key_handler(:SEMICOLON) { tank.aim_left }
    add_key_handler(:Q, :remove){ tank.aim_right }
    add_key_handler(:SPACE)     { fire }
  end

  def fire
    bullet = tank.fire
    bullets << bullet if bullet
  end

  def update n
    super

    if tank.x < 0 then tank.x = 0 elsif tank.x > w then tank.x = w end
    if tank.y < 0 then tank.y = 0 elsif tank.y > h then tank.y = h end
  end

  def draw n
    super

    fps n
  end
end

TankSprites.new.run
