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

  class View # TODO: not fond of view being mutative
    def self.draw w, b
      b.x = w.w/2
      b.y = w.h/2
      b.a = 90

      b.src.each do |line|
        case line
        when "pd" then
          b.pen = true
        when "pu" then
          b.pen = false
        when /rt (\d+)/ then
          b.a -= $1.to_i
        when /lt (\d+)/ then
          b.a += $1.to_i
        when /f (\d+)/ then
          dist = $1.to_i

          w.angle b.x, b.y, b.a, dist, :white if b.pen
          b.move_by b.a, dist
        else
          b.src.delete line
          warn "ERROR: #{line}"
        end
      end
      draw_turtle w, b.x, b.y, b.a
    end

    def self.draw_turtle w, x, y, a
      p1 = w.project(x, y, a, 15)
      p2 = w.project(x, y, a+90, 5)
      p3 = w.project(x, y, a-90, 5)

      w.polygon p1, p2, p3, :green
    end
  end
end

class Logo < Editor
  attr_accessor :turtle

  def initialize
    super
    self.turtle = Turtle.new self, lines
  end

  def draw_scene
    Turtle::View.draw self, turtle
  end
end

Logo.new.run if $0 == __FILE__
