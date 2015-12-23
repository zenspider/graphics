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

    self.t = Turret.new w, self
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
  attr_accessor :bs

  def initialize w, tank
    super w

    self.x = tank.x
    self.y = tank.y
    self.a = tank.a
    self.m = tank.m
    self.bs = w.bullets
  end

  def fire
    Bullet.new(x, y, a, m, bs, max_w, max_h).move_by a, 15
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
  attr_accessor :bs

  def initialize x, y, a, m, bs, max_w, max_h
    self.x = x
    self.y = y
    self.a = a
    self.m = m + 5
    self.max_w = max_w
    self.max_h = max_h
    self.bs = bs

    raise "Nil bs" unless bs
  end

  def update
    move
    bs.delete self if clip
  end

  class View
    def self.draw w, b
      w.rect b.x, b.y, 2, 2, :white
      w.debug "%.2f", b.m
    end
  end
end

class TargetSimulation < Graphics::Simulation
  attr_accessor :tank, :bullets
  attr_accessor :body_img
  attr_accessor :turret_img

  def initialize
    super 640, 640, 16, "Target Practice"

    self.bullets = []
    self.tank = Tank.new self

    register_body tank
    register_bodies bullets

    self.body_img   = image "resources/images/body.png"
    self.turret_img = image "resources/images/turret.png"
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
    add_key_handler(:SPACE)     { b = tank.fire; bullets << b if b }
  end

  def draw n
    super

    fps n
  end
end

TargetSimulation.new.run
