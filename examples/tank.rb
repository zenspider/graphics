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
    super w

    self.x = w.w / 2
    self.y = w.h / 2
    self.e = 0

    self.t = Turret.new self
  end

  def update
    self.e += TICK_ENERGY

    t.update x, y
    limit
    move &:bounce
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

  def draw
    w.blit w.body_img, x, y, a
    t.draw
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
    super tank.w
    self.position = tank.position
    self.m = tank.m
    self.a = tank.a
  end

  def fire
    b = Bullet.new w, x, y, a, m
    b.move_by a, 15
  end

  def update x, y
    self.x = x
    self.y = y
  end

  def draw
    w.blit w.turret_img, x, y, a
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
  end

  def update
    move
    w.bullets.delete self if clip
  end

  def draw
    w.rect x, y, 2, 2, :white
    w.debug "%.2f", m
  end
end

class TargetSimulation < Graphics::Simulation
  attr_accessor :tank, :bullets
  attr_accessor :body_img
  attr_accessor :turret_img

  def initialize
    super 640, 640, 16, "Target Practice"

    self.tank = Tank.new self
    self.bullets = []

    self.body_img   = image "resources/images/body.png"
    self.turret_img = image "resources/images/turret.png"
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

  def update n
    tank.update

    bullets.each(&:update)
  end

  def draw n
    clear
    tank.draw
    bullets.each(&:draw)
    fps n
  end
end

TargetSimulation.new.run
