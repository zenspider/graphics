1#!/usr/local/bin/ruby -w

# srand 42

require "thingy"

class Ball < Body
  TURN_STEP = 2
  G = 18 / 60.0
  R2D = 180.0 / Math::PI

  attr_accessor :g

  def initialize w
    super

    self.a = rand 180
    self.m = rand 100
    self.g = G
  end

  def update n
    fall
    move
    bounce
  end

  def dx_dy
    rad = a * D2R
    dx = Math.cos(rad) * m
    dy =-Math.sin(rad) * m
    return dx, dy
  end

  def set_dx_dy dx, dy
    self.a = (Math.atan2(-dy, dx) * R2D) % 360.0
    self.m = Math.sqrt(dx*dx + dy*dy)
  end

  def fall
    dx, dy = dx_dy

    dy += g # gravity is a constant downward force of 18

    set_dx_dy dx, dy
  end

  def draw n
    # w.angle x, y, a-45, 50, :yellow
    w.angle x, y, a, 60, :red
    # w.angle x, y, a+45, 50, :yellow

    w.circle x, y, 5, :white, :filled
    # w.debug "%3d, %3d @ %8.2f @ %8.2f" % [x, y, a, m]
  end
end

class BounceThingy < Thingy
  N = 25

  attr_accessor :bs

  def initialize
    super 640, 640, 16, "Bounce"

    self.bs = Array.new(N) { Ball.new self }
  end

  def update n
    bs.each do |b|
      b.update n
    end
  end

  def draw n
    clear :black

    bs.each do |b|
      b.draw n
    end

    fps n
  end

  def handle_keys
    super
    randomize if SDL::Key.press? SDL::Key::SPACE
    reverse if SDL::Key.press? SDL::Key::R
  end

  def randomize
    bs.each do |b|
      b.m = rand(100)
      b.a = rand(180)
    end
  end

  def reverse
    return if @guard
    @guard = true
    bs.each do |b|
      b.g *= -1
    end
    @guard = false
  end
end

BounceThingy.new.run
