#!/usr/local/bin/ruby -w

require "graphics"

class Ball < Graphics::Body
  COUNT = 50

  def initialize w
    super

    self.a = random_angle / 2
    self.m = rand 25
  end

  def draw
    w.angle x, y, a, 10+3*m, :red
    w.circle x, y, 5, :white, :filled
  end

  def update
    self.apply w.g
    move_bouncing
  end
end

class BounceSimulation < Graphics::Simulation
  attr_accessor :bs, :g

  def initialize
    super 640, 640, 16, "Bounce"

    self.bs = populate Ball
    self.g = Graphics::V.new a:-90, m:(3 / 10.0)
  end

  def initialize_keys
    super
    add_keydown_handler " ", &:randomize
    add_keydown_handler "r", &:reverse
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
    g.turn 180
  end

  LOG_INTERVAL = 120

  def log
    puts bs.map(&:m).inject(&:+)
  end
end

BounceSimulation.new.run
