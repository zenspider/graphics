# require "graphics"
# require "graphics/trail"

require "graphics"
require "graphics/trail"

# A way to compute pi as the ratio of the area of a polygon and the diameter of
# the enclosing circle. A set of bouncing bullets create new vertices as they
# hit the perimeter of the circle. As the number of vertices tends to infinite
# the polygon will converge to the circle and the ratio to pi.

srand 42

class Polygnome < Array
  attr_reader :origin, :r, :s

  def initialize center_x, center_y, w
    @s = w
    @r = w.r
    @origin = XY[center_x, center_y]
  end

  def draw
    if size > 2
      points = self << first
      points.each_cons(2) { |a, b| @s.line a.x, a.y, b.x, b.y, :yellow }
    end
  end

  def add vertex
    self << vertex

    if size > 2
      sort_radar
      SDL::WM.set_caption compute_pi, ''
    end
  end

  ##
  # Sort vertex like a radar, by angle to center
  def sort_radar
    sort_by! do |v|
      (360 + Math.atan2((v.y - origin.y), (v.x - origin.x))) % 360
    end
  end

  ##
  # Algorithm to compute area of polygon, needs vertex sorted in radar mode
  def compute_area
    sol = 0.0
    j = size - 1
    each_with_index do |v, i|
      sol += (self[j].x + v.x) * (self[j].y - v.y)
      j = i
    end
    (sol / 2.0).abs
  end

  def compute_pi
    "Pi: " + "%1.5f" % [compute_area / @r**2]
  end
end

class Bouncer < Graphics::Body
  attr_accessor :trail

  def initialize w, magnitude
    super w
    self.trail = Graphics::Trail.new(w, 6, color = :red)
    @s = w
    @r = w.r
    self.x = rand(w.screen.w/4) + w.r
    self.y = rand(w.screen.h/4) + w.r
    self.a = random_angle
    self.m = magnitude
  end

  def outside_circle? p
    (p.x - @r)**2 + (p.y - @r)**2 > @r**2
  end

  ##
  # Slope and offset of line given 2 points
  def line_to p
    slope  = (p.y - y) / (p.x - x)
    offset = y - (slope * x)
    [slope, offset]
  end

  ##
  # Intersection of enclosing circle and line y = ax + b. Algebraic solution
  def intersection_circle_and l
    a, b = l
    beta = Math.sqrt((2 * a * @r**2) - (2 * a * b * @r) - b**2 + (2 * b * @r))
    alfa = @r - (a * (b - @r))
    gama = (1 + a**2)

    x0 = [(alfa + beta)/gama, (alfa - beta)/gama].min_by {|e| (e - x).abs}
    y0 = a*x0 + b
    XY[x0, y0]
  end

  def draw
    trail.draw
  end

  def update
    e = endpoint
    if outside_circle? e
      i = intersection_circle_and line_to(e)
      self.position = i
      # turn (160 + rand(15) - 15)
      self.a = (a % 360) + (160 + rand(15) - 15)
      @s.poly.add i
    else
      move
      trail << self
    end
  end
end

class PiPolygon < Graphics::Simulation
  RADIO = 400
  BALLS = 15   #  2  30   100
  MAGND = 10   # 10  10   50

  attr_reader :r, :ball, :poly

  def initialize
    @r = RADIO
    super @r * 2, @r * 2
    @poly = Polygnome.new @r, @r, self
    @balls = []
    BALLS.times { @balls << Bouncer.new(self, MAGND) }
  end

  def draw n
    clear
    circle @r, @r, @r, :green
    @balls.each &:draw
    @poly.draw
  end

  def update n
    @balls.each &:update
  end
end

PiPolygon.new.run if $0 == __FILE__
