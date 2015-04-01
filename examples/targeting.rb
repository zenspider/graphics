#!/usr/bin/ruby -w

require "thingy"

class TargetThingy < Thingy
  attr_accessor :bombs

  def initialize
    super 640, 640, 16, "Target Practice"

    self.bombs = []
    register_color :dark_gray, 77,  77,  77
  end

  def handle_event event, n
    case event
    when SDL::Event::MouseButtonDown then
      bombs << [n, event.x, event.y]
    else
      super
    end
  end

  def draw n
    blank

    x, y, * = SDL::Mouse.state

    (0..640).step(64).each do |r|
      line 0, r, 640, r, :dark_gray
      line r, 0, r, 640, :dark_gray
      ellipse 320, 320, r, r, :dark_gray unless r > 320
    end

    line x, 0, x, 640, :white
    line 0, y, 640, y, :white

    text "#{x}, #{y}", 10, 10, :gray

    bombs.each do |(birth, bx, by)|
      r = n - birth
      ellipse bx, by, r, r, :yellow
    end
  end

  def update n
    bombs.reject! { |(birth, _, _)| (n-birth) > 100 }
  end
end

TargetThingy.new.run
