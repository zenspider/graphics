# -*- coding: utf-8 -*-

require "graphics/v"
require "graphics/extensions"

##
# A body in the simulation.
#
# A body is a fat vector (position, direction and magnitude), that knows
# its daddy (the simulation where it exists) plus some hot moves.

class Graphics::Body < Graphics::V

  ##
  # The cardinal directions.

  NORTH = 90
  SOUTH = -90
  EAST  = 0
  WEST  = 180

  ##
  # Body's environment.

  attr_accessor :env

  ##
  # Create a new body in windowing system +env+ with a new vector.

  def initialize env
    self.env = env
    super x:rand(env.w), y:rand(env.h)
  end

  ##
  # Update the body's state (usually its vector). To be overriden.

  def update
  end

  ##
  # Hop along the vector, so the endpoint becomes the new position.
  # Optionally pass a block to modify the body's vector before moving.

  def move &pre_block
    pre_block.yield(self) if block_given?

    self.position = endpoint
  end

  ##
  # Check see if the vector's endpoint is beyond the window boundaries.
  # If out of bounds, return the rebounding vector of the wall it hit.

  def wall_vectors
    max_h, max_w = env.h, env.w
    normals = []

    x2, y2 = endpoint.to_a
    dx, dy = dx_dy.to_a

    if x2 < 0 then
      normals << Graphics::V.new(a:EAST, m:-dx)
    elsif x2 > max_w then
      normals << Graphics::V.new(a:WEST, m:dx)
    end

    if y2 < 0 then
      normals << Graphics::V.new(a:NORTH, m:-dy)
    elsif y2 > max_h then
      normals << Graphics::V.new(a:SOUTH, m:dy)
    end

    normals
  end

  ##
  # Optional block when moving to keep body in bounds of the window. If out of
  # bounds, take body to the limit and apply a vector equal to it, and in the
  # opposite direction (in effect annulling its magnitude).

  def bound
    wall_vectors.each do |u|
      case u.a
      when EAST  then self.x = 0
      when WEST  then self.x = env.w
      when NORTH then self.y = 0
      when SOUTH then self.y = env.h
      end
      self.apply u
    end
  end

  ##
  # Optional block when moving to keep the body in bounds of the window,
  # bouncing off the walls. At wall the body encounters an opposite vector
  # twice its magnitude (minus friction) so in effect, rebounds.

  def bounce
    wall_vectors.each do |u|
      u.m *= 1.9
      self.apply u
    end
  end

  ##
  # Wrap the body if it hits an edge.

  def wrap
    max_h, max_w = env.h, env.w

    self.x = max_w if x < 0
    self.y = max_h if y < 0

    self.x = 0 if x > max_w
    self.y = 0 if y > max_h
  end
end
