#!/usr/local/bin/ruby -w
# -*- coding: utf-8 -*-

require "graphics"
$: << "."
require "examples/editor"

class Turtle < Graphics::Body
  attr_accessor :src, :pen

  def initialize w, src
    super w
    self.x = w.w/2
    self.y = w.h/2
    self.a = 90
    self.src = src
    self.pen = true
  end

  def draw
    self.x = w.w/2
    self.y = w.h/2
    self.a = 90

    src.each do |line|
      case line
      when "pd" then
        self.pen = true
      when "pu" then
        self.pen = false
      when /rt (\d+)/ then
        self.a -= $1.to_i
      when /lt (\d+)/ then
        self.a += $1.to_i
      when /f (\d+)/ then
        dist = $1.to_i

        w.angle x, y, a, dist, :white if pen
        move_by a, dist
      else
        src.delete line
        warn "ERROR: #{line}"
      end
    end
    draw_turtle
  end

  def draw_turtle
    p1 = w.project(x, y, a, 15)
    p2 = w.project(x, y, a+90, 5)
    p3 = w.project(x, y, a-90, 5)

    w.polygon p1, p2, p3, :green
  end
end

class Logo < Editor
  attr_accessor :turtle

  def initialize
    super
    self.turtle = Turtle.new self, lines
  end

  def draw_scene
    turtle.draw
  end
end

Logo.new.run if $0 == __FILE__
