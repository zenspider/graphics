#!/usr/bin/ruby -w

require "graphics"
require "set"

class ZenspiderGol
  delta   = [-1, 0, 1]
  same    = [0, 0]

  DELTAS  = (delta.product(delta) - [same])
  MIN     = { true => 2, false => 3 }

  @@neighbors = Hash.new { |h, k| h[k] = {} }

  attr_accessor :cells
  attr_accessor :cache

  def initialize
    self.cells = Set.new
  end

  def randomize n, pct
    m = ((n*n) * pct).to_i
    dimensions = n.times.to_a
    self.cells = dimensions.product(dimensions).sample(m).to_set
  end

  def update
    cells.replace considered.keep_if { |c| alive? c }
  end

  def considered
    cells.to_a.map { |c| neighbors_for c }.flatten(1).uniq
  end

  def alive? c
    neighbors_for(c).count { |o| cells.include? o }
                    .between? MIN[cells.include? c], 3
  end

  def neighbors_for c
    x, y = c
    @@neighbors[x][y] ||=
      DELTAS.map { |(dx, dy)| [x+dx, y+dy] }.reject { |(m, n)| m < 0 || n < 0 }
  end
end

class ZenspiderGolSimulation < Graphics::Simulation
  attr_accessor :gol

  SIZE, WIDTH = 10, 64

  def initialize
    super 640, 640, "Conway's Game of Life"

    self.gol = ZenspiderGol.new
    gol.randomize WIDTH, 0.15
  end

  def draw n
    clear

    gol.cells.each do |c|
      x, y = c
      ellipse x*SIZE, y*SIZE, (SIZE-1)/2, (SIZE-1)/2, :white, :filled
    end

    fps n
  end

  def update n
    gol.update.reject! { |(x, y)| x >= WIDTH || y >= WIDTH }
  end
end

if ARGV.first == "prof" then
  ZenspiderGolSimulation.new.run 5
else
  ZenspiderGolSimulation.new.run
end
