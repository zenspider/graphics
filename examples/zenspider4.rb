#!/usr/bin/ruby -w

srand 42

require "./thingy"

class Array
  def sorted_include? o
    a, b = o
    !!bsearch { |(x, y)|
      c = a - x
      c.zero? ? b - y : c
    }
  end
end

class ZenspiderGol
  delta   = [-1, 0, 1]
  same    = [0, 0]

  VERSION = "1.0.0"
  DELTAS  = (delta.product(delta) - [same]).sort
  MIN     = { true => 2, false => 3 }

  @@neighbors = Hash.new { |h, k| h[k] = {} }

  attr_accessor :cells
  attr_accessor :cache

  def initialize
    self.cells = []
  end

  def randomize n, pct
    m = ((n*n) * pct).to_i
    dimensions = n.times.to_a
    cells.replace dimensions.product(dimensions).sample(m).sort
  end

  def update
    cells.replace considered.select { |(x, y)| alive? x, y }.sort
  end

  def considered
    cells.map { |(x, y)| neighbors_for(x, y) }.flatten(1).uniq
  end

  def alive? x, y
    count = (neighbors_for(x, y) & cells).size
    min   = MIN[cells.sorted_include? [x, y]]
    count.between? min, 3
  end

  def neighbors_for x, y
    @@neighbors[x][y] ||=
      DELTAS.map { |(dx, dy)| [x+dx, y+dy] }.reject { |(m, n)| m < 0 || n < 0 }
  end
end

class ZenspiderGolThingy < Thingy
  attr_accessor :gol

  SIZE, WIDTH = 10, 64

  def initialize
    super 640, 640, 16, "Conway's Game of Life"

    self.gol = ZenspiderGol.new
    gol.randomize WIDTH, 0.15
  end

  def draw n
    blank

    gol.cells.each do |(x, y)|
      # fill_rect x*SIZE, y*SIZE, SIZE-1, SIZE-1, :white
      ellipse x*SIZE, y*SIZE, (SIZE-1)/2, (SIZE-1)/2, color.keys.sample

      text n.to_s, 10, 10, :green
    end
  end

  def update n
    gol.update.reject! { |(x, y)| x >= WIDTH || y >= WIDTH }
  end
end

if ARGV.first == "prof" then
  ZenspiderGolThingy.new.run 5
else
  ZenspiderGolThingy.new.run
end
