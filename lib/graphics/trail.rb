# -*- coding: utf-8 -*-

class Graphics::Trail
  @@c = {}

  attr_accessor :a, :w, :max, :c
  def initialize w, max, color = "green"
    self.w = w
    self.a = []
    self.max = max
    unless @@c[color] then
      @@c[color] ||= (0..99).map { |n| ("%s%02d" % [color, n]).to_sym }.reverse
    end
    self.c = @@c[color]
  end

  def draw
    m = 100.0 / max
    a.reverse_each.each_cons(2).with_index do |((x1, y1), (x2, y2)), i|
      w.line x1, y1, x2, y2, c[(i*m).round] || :black
    end
  end

  def << body
    a << [body.x, body.y]
    a.shift if a.size > max
    nil
  end
end
