# -*- coding: utf-8 -*-

require "graphics/v"
require "graphics/extensions"

##
# A body in the simulation.
#
# All bodies know their position, their angle, goal angle (optional),
# and momentum.

class Graphics::Body

  # degrees to radians
  D2R = Graphics::Simulation::D2R

  # radians to degrees
  R2D = Graphics::Simulation::R2D

  ##
  # The normals for the cardinal directions.

  NORMAL = {
           :north => 270,
           :south => 90,
           :east  => 180,
           :west  => 0,
           }

  ##
  # Body's x coordinate.

  attr_accessor :x

  ##
  # Body's y coordinate.

  attr_accessor :y

  ##
  # Body's angle, in degrees.

  attr_accessor :a

  ##
  # Body's goal angle, in degrees.

  attr_accessor :ga

  ##
  # Body's magnitude.

  attr_accessor :m

  attr_accessor :max_w
  attr_accessor :max_h

  ##
  # Create a new body in windowing system +w+ with a random x/y and
  # everything else zero'd out.

  def initialize w
    self.max_w, self.max_h = w.w, w.h
    self.x, self.y = rand(w.w), rand(w.h)
    self.a = 0.0
    self.ga = 0.0
    self.m = 0.0
  end

  def inspect # :nodoc:
    "%s(%.2fx%.2f @ %.2f°x%.2f == %p @ %p)" %
      [self.class, x, y, a, m, position, velocity]
  end

  ##
  # Convert the body to a vector representing its velocity.
  #
  # DO NOT modify this vector expecting it to modify the body. It is a
  # copy.

  def velocity
    x, y = dx_dy
    V[x, y]
  end

  ##
  # Set the body's magnitude and angle from a velocity vector.

  def velocity= o
    dx, dy = o.x, o.y
    self.m = Math.sqrt(dx*dx + dy*dy)
    self.a = Math.atan2(dy, dx) * R2D
  end

  ##
  # Convert the body to a vector representing its position.
  #
  # DO NOT modify this vector expecting it to modify the body. It is a
  # copy.

  def position
    V[x, y]
  end

  ##
  # Set the body's position from a velocity vector.

  def position= o
    self.x = o.x
    self.y = o.y
  end

  def dx_dy # :nodoc:
    rad = a * D2R
    dx = Math.cos(rad) * m
    dy = Math.sin(rad) * m
    [dx, dy]
  end

  ##
  # Return the angle to another body in degrees.

  def angle_to body
    dx = body.x - self.x
    dy = body.y - self.y

    (R2D * Math.atan2(dy, dx)).degrees
  end

  ##
  # Return the distance to another body, squared.

  def distance_to_squared p
    dx = p.x - x
    dy = p.y - y
    dx * dx + dy * dy
  end

  def m_a # :nodoc:
    [m, a]
  end

  ##
  # Turn the body +dir+ degrees.

  def turn dir
    self.a = (a + dir).degrees if dir
  end

  ##
  # Move the body via its current angle and momentum.

  def move
    move_by a, m
  end

  ##
  # Move the body by a specified angle and momentum.

  def move_by a, m
    rad = a * D2R
    self.x += Math.cos(rad) * m
    self.y += Math.sin(rad) * m
    self
  end

  ##
  # Keep the body in bounds of the window. If it went out of bounds,
  # set its position to be on that bound and return the cardinal
  # direction of the wall it hit.
  #
  # See also: NORMALS

  def clip
    if x < 0 then
      self.x = 0
      return :west
    elsif x > max_w then
      self.x = max_w
      return :east
    end

    if y < 0 then
      self.y = 0
      return :south
    elsif y > max_h then
      self.y = max_h
      return :north
    end

    nil
  end

  ##
  # Return a random angle 0...360.

  def random_angle
    360 * rand
  end

  ###
  # Randomly turn the body inside an arc of +deg+ degrees from where
  # it is currently facing.

  def random_turn deg
    rand(deg) - (deg/2)
  end

  ##
  # clip and then set the goal angle to the normal plus or minus a
  # random 45 degrees.

  def clip_off_wall
    if wall = clip then
      normal = NORMAL[wall]
      self.ga = (normal + random_turn(90)).degrees unless (normal - ga).abs < 45
    end
  end

  ##
  # Like clip, keep the body in bounds of the window, but set the
  # angle to the angle of reflection. Also slows momentum by 20%.

  def bounce
    # TODO: rewrite this using clip + NORMAL to clean it up
    normal = nil

    if x < 0 then
      self.x, normal = 0, 0
    elsif x > max_w then
      self.x, normal = max_w, 180
    end

    if y < 0 then
      self.y, normal = 0, 90
    elsif y > max_h then
      self.y, normal = max_h, 270
    end

    if normal then
      self.a = (2 * normal - 180 - a).degrees
      self.m *= 0.8
    end
  end

  ##
  # Wrap the body if it hits an edge.

  def wrap
    self.x = max_w if x < 0
    self.y = max_h if y < 0

    self.x = 0 if x > max_w
    self.y = 0 if y > max_h
  end
end
