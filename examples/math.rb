#!/usr/bin/ruby -w

require "thingy"

class MathThingy < Thingy
  def initialize
    super 640, 640, 16, "Math"
  end

  def draw n
    graph_paper

    (0..w).each do |x|
      # (x + 3)(2x - 4)
      # 2x^2 -4x +6x -12
      # 2x^2 +2x -12

      y = 2*x*x + 2*x - 12
      y /= 320.0

      next if y < 0
      next if y > h

      rect x, h-y, 3, 3, :red, :filled
    end

    text "2x^2 +2x -12", 10, 10, :black
  end

  def graph_paper
    clear :white

    hline h-1, :black
    vline 0,   :black

    (0..w).step(25).each do |x|
      (0..h).step(25).each do |y|
        line 0, h-y, 5, h-y, :black if x == 0
        line x, h-5, x, h,   :black if y == 0
        point x, h-y, :black
      end
    end
  end
end

MathThingy.new.run
