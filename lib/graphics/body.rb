# -*- coding: utf-8 -*-

require "graphics/v"
require "graphics/extensions"

class Graphics::Body
  D2R = Graphics::Simulation::D2R
  R2D = Graphics::Simulation::R2D

  V_ZERO = V::ZERO

  NORMAL = {
           :north => 270,
           :south => 90,
           :east  => 180,
           :west  => 0,
           }

  attr_accessor :x, :y, :a, :ga, :m, :w

  def initialize w
    self.w = w

    self.x, self.y = rand(w.w), rand(w.h)
    self.a = 0.0
    self.ga = 0.0
    self.m = 0.0
  end

  def inspect
    "%s(%.2fx%.2f @ %.2f°x%.2f == %p @ %p)" %
      [self.class, x, y, a, m, position, velocity]
  end

  def velocity
    x, y = dx_dy
    V[x, y]
  end

  def velocity= o
    dx, dy = o.x, o.y
    self.m = Math.sqrt(dx*dx + dy*dy)
    self.a = Math.atan2(dy, dx) * R2D
  end

  def position
    V[x, y]
  end

  def position= o
    self.x = o.x
    self.y = o.y
  end

  def dx_dy
    rad = a * D2R
    dx = Math.cos(rad) * m
    dy = Math.sin(rad) * m
    [dx, dy]
  end

  def m_a
    [m, a]
  end

  def turn dir
    self.a = (a + dir) % 360.0 if dir
  end

  def move
    move_by a, m
  end

  def move_by a, m
    rad = a * D2R
    self.x += Math.cos(rad) * m
    self.y += Math.sin(rad) * m
  end

  def clip
    max_h, max_w = w.h, w.w

    if x < 0 then
      self.x = 0
      return :west
    elsif x > max_w then
      self.x = max_w
      return :east
    end

    if y < 0 then
      self.y = 0
      return :north
    elsif y > max_h then
      self.y = max_h
      return :south
    end

    nil
  end

  def random_angle
    360 * rand
  end

  def random_turn deg
    rand(deg) - (deg/2)
  end

  def clip_off_wall
    if wall = clip then
      normal = NORMAL[wall]
      self.ga = (normal + random_turn(90)).degrees unless (normal - ga).abs < 45
    end
  end

  def bounce
    max_h, max_w = w.h, w.w
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

  def wrap
    max_h, max_w = w.h, w.w

    self.x = max_w if x < 0
    self.y = max_h if y < 0

    self.x = 0 if x > max_w
    self.y = 0 if y > max_h
  end
end
