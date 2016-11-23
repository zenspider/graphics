#!/usr/bin/ruby -w

require "thingy"

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
end

class TargetThingy < Thingy
  attr_accessor :tank, :bullets
  attr_accessor :body_img
  attr_accessor :turret_img

  def initialize
    super 640, 640, 16, "Target Practice"

    SDL::Key.enable_key_repeat 50, 10

    self.tank = Tank.new w/2, h/2
    self.bullets = []

    screen.set_alpha SDL::SRCALPHA, 128

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

  def handle_keys
    exit            if SDL::Key.press? SDL::Key::ESCAPE
    tank.turn_right if SDL::Key.press? SDL::Key::RIGHT
    tank.turn_left  if SDL::Key.press? SDL::Key::LEFT
    tank.accelerate if SDL::Key.press? SDL::Key::UP
    tank.decelerate if SDL::Key.press? SDL::Key::DOWN
    tank.aim_left   if SDL::Key.press? SDL::Key::SEMICOLON
    tank.aim_right  if SDL::Key.press? SDL::Key::Q
    fire            if SDL::Key.press? SDL::Key::SPACE
  end

  def fire
    bullet = tank.fire
    bullets << bullet if bullet
  end

  def update n
    tank.update

    bullets.each(&:update)

    if tank.x < 0 then tank.x = 0 elsif tank.x > w then tank.x = w end
    if tank.y < 0 then tank.y = 0 elsif tank.y > h then tank.y = h end
  end

  def draw n
    clear
    draw_tank
    draw_bullets
    fps n
  end

  AA = SDL::Surface::TRANSFORM_AA

  def draw_tank
    x, y, a, t = tank.x, tank.y, tank.angle, tank.turret

    blit body_img, x, y, a, AA
    blit turret_img, x, y, t, AA

    debug "%3d @ %.2f @ %d", tank.angle, tank.speed, tank.energy
  end

  def draw_bullets
    bullets.each do |b|
      rect b.x, b.y, 2, 2, :white
    end
  end
end

TargetThingy.new.run
