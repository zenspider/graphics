require "graphics"
require "graphics/trail"

# A way to compute pi as the ratio of the area of a polygon and the diameter of
# the enclosing circle. A set of bouncing bullets create new vertices as they
# hit the perimeter of the circle. As the number of vertices tends to infinite
# the polygon will converge to the circle and the ratio to pi.

class Polygnome < Array
  attr_reader :origin, :r, :s

  def initialize center_x, center_y, w
    @s = w
    @r = w.r
    @origin = V[center_x, center_y]
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
  attr_reader :x, :y, :a, :m, :r, :s
  attr_accessor :trail

  def initialize w, magnitude
    super w
    self.trail = Graphics::Trail.new(w, 6, color = :red)
    @s = w
    @r = w.r
    @x = rand(w.renderer.w/4) + w.r
    @y = rand(w.renderer.h/4) + w.r
    @a = random_angle
    @m = magnitude
  end

  def target_point
    rad = @a * D2R
    V[@x + Math.cos(rad) * @m, @y + Math.sin(rad) * @m]
  end

  def outside_circle? v
    (v.x - @r)**2 + (v.y - @r)**2 > @r**2
  end

  ##
  # Slope and offset of line given 2 points
  def line_to p
    slope  = (p.y - @y) / (p.x - @x)
    offset = @y - (slope * @x)
    [slope, offset]
  end

  ##
  # Intersection of enclosing circle and line y = ax + b. Algebraic solution
  def intersection_circle_and l
    a, b = l
    beta = Math.sqrt((2 * a * @r**2) - (2 * a * b * @r) - b**2 + (2 * b * @r))
    alfa = @r - (a * (b - @r))
    gama = (1 + a**2)

    x0 = [(alfa + beta)/gama, (alfa - beta)/gama].min_by {|e| (e - @x).abs}
    y0 = a*x0 + b
    V[x0, y0]
  end

  class View
    def self.draw w, b
      b.trail.draw # TODO: remove w stored everywhere
    end
  end

  def update
    t = target_point
    if outside_circle? t
      t = intersection_circle_and line_to(t)
      turn (160 + rand(15) - 15)
      @s.poly.add t
    end
    self.position = t
    trail << self
  end
end

class PiPolygon < Graphics::Simulation
  RADIO = 400
  BALLS = 10   #  2  30   100
  MAGND = 10   # 10  10   50

  attr_reader :r, :ball, :poly

  def initialize
    @r = RADIO
    super @r * 2, @r * 2
    @poly = Polygnome.new @r, @r, self
    @balls = []
    register_bodies @balls
    BALLS.times { @balls << Bouncer.new(self, MAGND) }
  end

  def update n
    super

    self.renderer.title = poly.compute_pi
  end

  def draw n
    super
    circle @r, @r, @r, :green
    @poly.draw
  end
end

PiPolygon.new.run if $0 == __FILE__
