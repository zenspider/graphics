#!/usr/bin/ruby -w

srand 42

class GameOfLife
  attr_accessor :cells
  attr_accessor :cache

  def initialize
    self.cells = []
  end

  def randomize n, m
    dimensions = n.times.to_a
    cells.replace dimensions.product(dimensions).sample(m).sort
  end

  def run max = 1.0 / 0
    (1..max).each do |n|
      yield n
      update
    end
  end

  def update
    cells.replace considered.select { |(x, y)| alive? x, y }.sort
  end

  def considered
    cells.map { |(x, y)| neighbors_for(x, y) }.flatten(1).uniq
  end

  MIN = { true => 2, false => 3 }

  def alive? x, y
    count = (neighbors_for(x, y) & cells).size
    min   = MIN[cells.include? [x, y]]
    count.between? min, 3
  end

  delta  = [-1, 0, 1]
  same   = [0, 0]
  DELTAS = (delta.product(delta) - [same])

  @@neighbors = Hash.new { |h, k| h[k] = {} }

  def neighbors_for x, y
    DELTAS.map { |(dx, dy)| [x+dx, y+dy] }.reject { |(m, n)| m < 0 || n < 0 }
  end
end

size, width, count = 20, 32, 512

gol = GameOfLife.new
gol.randomize width, count

if ARGV.first == "prof" then
  gol.run 50 do
    $stderr.print "."
  end
  warn "done"
else
  require "sdl"

  SDL.init SDL::INIT_VIDEO
  SDL::WM.set_caption "Conway's Game of Life", "Conway's Game of Life"

  screen = SDL::Screen.open 640, 640, 16, SDL::DOUBLEBUF

  black = screen.format.map_rgb   0,   0,   0
  white = screen.format.map_rgb 255, 255, 255

  w, h = screen.w, screen.h

  gol.run do
    screen.fill_rect 0, 0, w, h, black

    gol.cells.each do |(x, y)|
      screen.fill_rect x*size, y*size, size-1, size-1, white
    end

    screen.flip

    while event = SDL::Event.poll
      case event
      when SDL::Event::KeyDown,  SDL::Event::Quit
        exit
      end
    end

    gol.update
  end
end
