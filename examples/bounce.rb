#!/usr/local/bin/ruby -w

require "thingy"

class Ball < Body
  COUNT = 50

  G = V[0, -18 / 60.0]

  attr_accessor :g

  def initialize w
    super

    self.a = rand 180
    self.m = rand 100
    self.g = G
  end

  def update
    fall
    move
    bounce
  end

  def fall
    self.velocity += g
  end

  def label
    l = "%.1f %.1f" % dx_dy
    w.text l, x-10, y-40, :white
  end

  def draw
    # w.angle x, y, a, 3*m, :red
    w.angle x, y, a, 50, :red
    w.circle x, y, 5, :white, :filled
    # label
  end
end

class BounceSimulation < Simulation
  attr_accessor :bs

  def initialize
    super 640, 640, 16, "Bounce"

    self.bs = populate Ball
  end

  def update n
    bs.each(&:update)
  end

  def draw n
    clear
    bs.each(&:draw)
    bs.first.label
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

BounceSimulation.new.run
