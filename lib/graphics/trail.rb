# -*- coding: utf-8 -*-

##
# A simple "trail" class, that draws the path of a in a particular hue.
#
#   # ... in initialize
#   self.trail = Trail.new self, 100, :white
#
#   # ... in Body#update
#   trail << body
#
#   # ... in Body#draw
#   trail.draw

class Graphics::Trail
  @@c = {}

  ##
  # The array of x/y coordinates of the trail.

  attr_accessor :a

  ##
  # The windowing system we're drawing in.

  attr_accessor :w

  ##
  # The maximum number of segments to keep in the trail.

  attr_accessor :max

  ##
  # The hues to draw in the trail.

  attr_accessor :c

  ##
  # Create a Trail with +max+ length and of a particular +color+ hue.

  def initialize w, max, color = :green
    self.w = w
    self.a = []
    self.max = max
    unless @@c[color] then
      @@c[color] ||= (0..99).map { |n| ("%s%02d" % [color, n]).to_sym }.reverse
    end
    self.c = @@c[color]
  end

  ##
  # Draw the trail and taper off the color as we go.

  def draw
    m = 100.0 / max
    a.reverse_each.each_cons(2).with_index do |((x1, y1), (x2, y2)), i|
      w.line x1, y1, x2, y2, c[(i*m).round] || :black
    end
  end

  ##
  # Add another segment to the trail, and remove a segment if needed.

  def << body
    a << [body.x, body.y]
    a.shift if a.size > max
    nil
  end
end
