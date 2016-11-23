#!/usr/local/bin/ruby -w

require "graphics"

class Ball < Graphics::Body
  COUNT = 50

  G = V[0, -18 / 60.0]

  attr_accessor :g

  def initialize w
    super

    self.a = random_angle / 2
    self.m = rand 25
    self.g = G
  end

  def draw
    w.angle x, y, a, 10+3*m, :red
    w.circle x, y, 5, :white, :filled
  end

  def update
    fall
    move
    bounce
  end

  def fall
    self.velocity += g
  end
end

class BounceSimulation < Graphics::Simulation
  attr_accessor :bs

  def initialize
    super 640, 640, 16, "Bounce"

    self.bs = populate Ball
  end

  def initialize_keys
    super
    add_key_handler :SPACE, &:randomize
    add_key_handler :R,     &:reverse
  end

  def update n
    bs.each(&:update)
  end

  def draw n
    clear
    bs.each(&:draw)
    fps n
  end

  def randomize
    bs.each do |b|
      b.m = rand(25)
      b.a = b.random_angle / 2
    end
  end

  def reverse
    bs.each do |b|
      b.g *= -1
    end
  end
end

BounceSimulation.new.run
