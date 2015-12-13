# Minimalistic functional approach to Conway's Game of Life
# rule I: living cells survive if surrounded by 2-3 living cells
# rule II: nearby cells spawn if surrounded by 3 living cells

srand 42

require "graphics"

module GOL
  def self.tick old_cells
    new_cells = {}

    old_cells.each do |c, _|
      nearby = neighbors c

      new_cells[c] = nearby.count { |x| old_cells[x] }.between? 2, 3  # rule I

      nearby.each do |n|
        next if old_cells[n] || new_cells.member?(n)
        new_cells[n] = neighbors(n).count { |x| old_cells[x] } == 3   # rule II
      end
    end

    return new_cells.select{ |_, v| v }
  end

  def self.neighbors cell
    x, y = cell
    [x + 1, x, x - 1].product([y - 1, y, y + 1]) - [[x, y]]
  end
end

class SotoGOL < Graphics::Simulation
  include GOL

  attr_accessor :board

  SIDE_PIXELS = 640 # number of pixels per side of the board
  SIDE_CELLS  = 64  # number of cells  per side of the board

  def initialize
    super SIDE_PIXELS, SIDE_PIXELS, 16, "Conway's Game of Life"

    self.board = {}
    @k = SIDE_PIXELS / SIDE_CELLS
    @r = @k/3
    randomize SIDE_CELLS, 0.15
  end

  def randomize n, pct # zenspider's randomizer
    b = []
    m = ((n*n) * pct).to_i
    dimensions = n.times.to_a
    b.replace dimensions.product(dimensions).sample(m).sort
    self.board = Hash[b.zip(Array.new(b.size, true))]
  end

  def update n
    self.board = GOL::tick self.board
    board.delete_if do |c, _|
      x, y = c
      x < 0 || y < 0 || x > @w - 1 || y > @h - 1
    end
  end

  def draw n
    clear
    self.board.keys.each { |x, y| circle x*@k+@r, y*@k+@r, @r, :green, :fill }
    fps n
  end
end

SotoGOL.new.run
