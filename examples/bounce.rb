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

  def update
    fall
    move
    bounce
  end

  def fall
    self.velocity += g
  end

  class View
    def self.draw w, b
      w.angle  b.x, b.y, b.a, 10+3*b.m, :red
      w.circle b.x, b.y, 5,             :white,   :filled
    end
  end
end

class BounceSimulation < Graphics::Simulation
  attr_accessor :bs

  def initialize
    super

    self.bs = populate Ball
    register_bodies bs
  end

  def initialize_keys
    super
    add_keydown_handler " ", &:randomize
    add_keydown_handler "r", &:reverse
  end

  def draw n
    super
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

  LOG_INTERVAL = 120

  def log
    puts "%.1f" % bs.inject(0) { |ms, o| ms + o.m }
  end
end

BounceSimulation.new.run
