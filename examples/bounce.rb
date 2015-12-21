#!/usr/local/bin/ruby -w

require "graphics"

class Ball < Graphics::Body
  COUNT = 50

  def initialize env
    super

    self.a = random_angle / 2
    self.m = rand 25
  end

  def update
    apply env.gravity
    move(&:bounce)
  end

  class View
    def self.draw w, o
      w.angle o.x, o.y, o.a, 10+3*o.m, :red
      w.circle o.x, o.y, 5, :white, :filled
    end
  end

end

class BounceSimulation < Graphics::Simulation
  attr_accessor :gravity

  def initialize
    super 640, 640, 16, "Bounce"

    self.env.gravity = Graphics::V.new a:-90, m:(3 / 10.0)
    register_bodies populate Ball
  end

  def initialize_keys
    super
    add_keydown_handler " ", &:randomize
    add_keydown_handler "r", &:reverse
  end

  def randomize
    self.env._bodies.each do |b|
      b.m = rand(25)
      b.a = b.random_angle / 2
    end
  end

  def reverse
    self.env.gravity.turn 180
  end

  LOG_INTERVAL = 120

  def log
    puts self.env._bodies.flatten.map(&:m).inject(&:+)
  end
end

BounceSimulation.new.run
