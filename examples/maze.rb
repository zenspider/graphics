#!/usr/local/bin/ruby -w
# -*- coding: utf-8 -*-

require "graphics"

##
# All code here is adapted from Jamis Buck's Mazes for Programmers.
# Used with Permission.

class Cell
  attr_reader :row, :column
  attr_accessor :north, :south, :east, :west

  def initialize(row, column)
    @row, @column = row, column
    @links = {}
  end

  def link(cell, bidi=true)
    @links[cell] = true
    cell.link(self, false) if bidi
    self
  end

  def linked?(cell)
    @links.key?(cell)
  end
end

class Grid
  attr_reader :rows, :columns, :w

  def initialize(rows, columns, w)
    @rows = rows
    @columns = columns
    @w = w

    @grid = prepare_grid
    configure_cells
  end

  def prepare_grid
    Array.new(rows) do |row|
      Array.new(columns) do |column|
        Cell.new(row, column)
      end
    end
  end

  def configure_cells
    each_cell do |cell|
      row, col = cell.row, cell.column

      cell.north = self[row - 1, col]
      cell.south = self[row + 1, col]
      cell.west  = self[row, col - 1]
      cell.east  = self[row, col + 1]
    end
  end

  def [](row, column)
    return nil unless row.between?(0, @rows - 1)
    return nil unless column.between?(0, @grid[row].count - 1)
    @grid[row][column]
  end

  def each_row
    @grid.each do |row|
      yield row
    end
  end

  def each_cell
    each_row do |row|
      row.each do |cell|
        yield cell if cell
      end
    end
  end

  def draw n
    cell_size = w.w / columns

    each_cell do |cell|
      x1 = cell_size * cell.column
      y1 = cell_size * cell.row
      x2 = cell_size * (cell.column + 1)
      y2 = cell_size * (cell.row + 1)

      w.line x1, y1, x2, y1, :white unless cell.north
      w.line x1, y1, x1, y2, :white unless cell.west
      w.line x2, y1, x2, y2, :white unless cell.linked? cell.east
      w.line x1, y2, x2, y2, :white unless cell.linked? cell.south
    end
  end
end

class BinaryTree
  def self.on(grid)
    grid.each_cell do |cell|
      neighbors = []
      neighbors << cell.north if cell.north
      neighbors << cell.east if cell.east

      index = rand(neighbors.length)
      neighbor = neighbors[index]

      cell.link(neighbor) if neighbor
    end

    grid
  end
end

class Maze < Graphics::Simulation
  attr_accessor :grid

  def initialize
    super 800, 800

    self.grid = Grid.new 50, 50, self
    BinaryTree.on grid
  end

  def update n
    # do nothing
  end

  def draw n
    clear

    grid.draw n
  end
end

Maze.new.run if $0 == __FILE__
