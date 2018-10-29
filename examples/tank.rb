#!/usr/bin/ruby -w

require "graphics"

D2R = Math::PI / 180.0

class Tank < Graphics::Body
  ACCELERATE   = 0.25
  DECELERATE   = 0.125
  ROTATION     = 2
  TICK_ENERGY  = 5
  SHOT_ENERGY  = 100

  BULLET_SPEED = 9.0
  MAX_SPEED    = 4.0
  MAX_ROTATION = 360
  MAX_ENERGY   = 100

  attr_accessor :t
  attr_accessor :e

  def initialize w
    super

    self.x = w.w / 2
    self.y = w.h / 2
    self.e = 0

    self.t = Turret.new self
  end

  def update
    self.e += TICK_ENERGY

    t.update x, y
    move
    limit
    clip
  end

  def limit
    self.e = MAX_ENERGY if e > MAX_ENERGY

    if m > MAX_SPEED then
      self.m = MAX_SPEED
    elsif m < 0 then
      self.m = 0
    end
  end

  def fire
    if e >= SHOT_ENERGY then
      self.e -= SHOT_ENERGY
      t.fire
    end
  end

  class View
    def self.draw w, b
      w.blit w.body_img, b.x, b.y, b.a
      Turret::View.draw w, b.t
    end
  end

  def turn_right; turn(-ROTATION); aim_right; end
  def turn_left;  turn ROTATION;   aim_left;  end

  def aim_right;  self.t.turn(-ROTATION); end
  def aim_left;   self.t.turn ROTATION;   end

  def accelerate; self.m += ACCELERATE; self.t.m = m; end
  def decelerate; self.m -= DECELERATE; self.t.m = m; end
end

class Turret < Graphics::Body
  def initialize tank
    self.w = tank.w
    self.x = tank.x
    self.y = tank.y
    self.a = tank.a
    self.m = tank.m
  end

  def fire
    b = Bullet.new w, x, y, a, m
    b.move_by a, 15
  end

  def update x, y
    self.x = x
    self.y = y
  end

  class View
    def self.draw w, b
      w.blit w.turret_img, b.x, b.y, b.a
    end
  end
end

class Bullet < Graphics::Body
  def initialize w, x, y, a, m
    self.w = w
    self.x = x
    self.y = y
    self.a = a
    self.m = m + 5
    w.bullets << self
    w.bullet_snd.play
  end

  def update
    move
    w.bullets.delete self if clip
  end

  class View
    def self.draw w, b
      w.rect b.x, b.y, 2, 2, :white
      w.debug "%.2f", b.m
    end
  end
end

class Tanks < Graphics::Simulation
  attr_accessor :tank, :bullets
  attr_accessor :body_img
  attr_accessor :turret_img
  attr_accessor :bullet_snd

  def initialize
    super 640, 640

    self.tank = Tank.new self
    self.bullets = []

    open_mixer 8
    register_body tank
    register_bodies bullets

    self.body_img   = image "resources/images/body.png"
    self.turret_img = image "resources/images/turret.png"
    self.bullet_snd = audio "resources/sounds/bullet.wav"
  end

  def initialize_keys
    super

    add_key_handler(:RIGHT)     { tank.turn_right }
    add_key_handler(:LEFT)      { tank.turn_left }
    add_key_handler(:UP)        { tank.accelerate }
    add_key_handler(:DOWN)      { tank.decelerate }
    add_key_handler(:SEMICOLON) { tank.aim_left }
    add_key_handler(:Q, :remove){ tank.aim_right }
    add_key_handler(:SPACE)     { tank.fire }
  end

  def draw n
    super

    fps n
  end
end

Tanks.new.run
