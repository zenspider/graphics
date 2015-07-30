require 'matrix'

class Matrix
  def rotate x, y
    # I can't find a neat matrix-math solution for
    # this, so let's do it with regular 'ol `map`.
    Matrix[ *self.to_a.rotate(y).map {|row| row.rotate x} ]
  end

  # Pad or shrink a matrix
  def take x, y
    Matrix.build(y, x){|i, j| if self[i, j].nil? then 0 else self[i, j] end }
  end

  # Bitwise operations on boolean matrices
  def & other
    Matrix.Raise ErrDimensionMismatch unless
      self.row_count == other.row_count and
      self.column_count == other.column_count

    Matrix.build(self.row_count){|i, j| self[i, j] & other[i, j] }
  end

  def | other
    Matrix.Raise ErrDimensionMismatch unless
      self.row_count == other.row_count and
      self.column_count == other.column_count

    Matrix.build(self.row_count){|i, j| self[i, j] | other[i, j] }
  end
end

def sum l
  l.reduce :+
end

def twos grid
  grid.map{|i| if i == 2 then 1 else 0 end}
end

def threes grid
  grid.map{|i| if i == 3 then 1 else 0 end}
end

AROUND = [-1, 0, 1].product([-1, 0, 1])

def neighbors grid
  sum(AROUND.map{|x, y| grid.rotate x, y } ) - grid
end

def life grid
  ((twos neighbors grid) & grid) | (threes neighbors grid)
end

size, width, count = 10, 64, 256

require "sdl"

SDL.init SDL::INIT_VIDEO
SDL::WM::set_caption "Conway's Game of Life", "Conway's Game of Life"

screen = SDL::Screen.open 640, 640, 16, SDL::HWSURFACE|SDL::DOUBLEBUF

black = screen.format.map_rgb   0,   0,   0
white = screen.format.map_rgb 255, 255, 255

w, h = screen.w, screen.h

matrix = Matrix[[1, 1, 1],
                [0, 0, 1],
                [1, 1, 1]].take(width, width).rotate(-(width/2), -(width/2))

paused = false
step = false
(1..(1.0/0)).each do |n|
  puts n if n % 100 == 0

  screen.fill_rect 0, 0, w, h, black

  matrix.to_a.each_with_index do |row, y|
    row.each_with_index do |c, x|
      if c == 1 then
        screen.fill_rect x*size, y*size, size-1, size-1, white
      end
    end
  end

  screen.flip

  while event = SDL::Event.poll
    case event
    when SDL::Event::KeyDown then
      c = event.sym.chr
      exit if c == "q" or c == "Q" or c == "\e"
      step = true if c == " "
      puts n
      paused = ! paused
    when SDL::Event::Quit then
      exit
    end
  end

  sleep 0.01
  matrix = life matrix unless paused
  if step then
    paused = true
    step = false
  end
end
