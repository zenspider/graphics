#!/usr/bin/ruby -w

require "graphics"

class MathSimulation < Graphics::Simulation
  CLEAR_COLOR = :white

  def initialize
    super 640, 640
  end

  def draw n
    graph_paper

    (0..w).each do |x|
      y = 2*x*x + 2*x - 12
      y /= 320.0

      next if y < 0
      next if y > h

      rect x, y, 3, 3, :red, :filled
    end

    text "2x^2 +2x -12", 10, h-font.height, :black
  end

  def graph_paper
    clear

    hline 1, :black
    vline 0, :black

    (0..w).step(25).each do |x|
      (0..h).step(25).each do |y|
        line 0, y, 5, y, :black if x == 0
        line x, 1, x, 6, :black if y == 0
        point x, h-y, :black
      end
    end
  end
end

MathSimulation.new.run
