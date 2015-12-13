# Axial projection of coordinates in 2D.

class XY

  # radians to degrees
  R2D = Graphics::Simulation::R2D

  # projection over x coordinate axis -- preferably float
  attr_accessor :x

  # projection over y coordinate axis -- preferably float
  attr_accessor :y

  class << self
    alias :[] :new # :nodoc:
  end

  ##
  # Create a new axial projection with x & y segments.

  def initialize x, y
    @x = x
    @y = y
  end

  # Origin projection
  ZERO = XY[0.0, 0.0]

  # Point at one projection
  ONE  = XY[1.0, 1.0]

  ##
  # Add the axial projections of two points, returning a new XY.

  def + q
    XY[x+q.x, y+q.y]
  end

  ##
  # Subtract the axial projections of two points, returning a new XY.

  def - q
    XY[x-q.x, y-q.y]
  end

  ##
  # Multiply the projections of a point by a scalar, returning a new XY.

  def * s
    XY[x*s, y*s]
  end

  ##
  # Divide the projections of a point by a scalar, returning a new XY.

  def / s
    XY[x/s, y/s]
  end

  def == other # :nodoc:
    x == other.x && y == other.y
  end

  ##
  # Return the distance from the origin to the projected point.

  def magnitude
    Math.sqrt(x*x + y*y)
  end

  ##
  # Return the distance to another point, squared.

  def distance_to_squared p2
    dxy = p2 - self
    dxy.x ** 2 + dxy.y ** 2
  end

  ##
  # Return the angle to another point in degrees.

  def angle_to p2
    dxy = p2 - self
    (R2D * Math.atan2(dxy.y, dxy.x)).degrees
  end

  def inspect # :nodoc:
    "#{self.class.name}[%.2f, %.2f]" % [x, y]
  end
  alias to_s inspect # :nodoc:

  def to_a
    [x, y]
  end
end
