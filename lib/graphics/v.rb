##
# Simple and fast 2 dimensional vector

class V
  # x coordinate accessors -- preferably float
  attr_accessor :x
  # y coordinate accessors -- preferably float
  attr_accessor :y

  class << self
    alias :[] :new # :nodoc:
  end

  ##
  # Create a new vector with x & y coordinates.

  def initialize x, y
    @x = x
    @y = y
  end

  # zero vector
  ZERO = V[0.0, 0.0]

  # one vector
  ONE  = V[1.0, 1.0]

  ##
  # Add two vectors, returning a new vector.

  def + v
    V[x+v.x, y+v.y]
  end

  ##
  # Subtract two vectors, returning a new vector.

  def - v
    V[x-v.x, y-v.y]
  end

  ##
  # Multiply a vector by a scalar, returning a new vector.

  def * s
    V[x*s, y*s]
  end

  ##
  # Divide a vector by a scalar, returning a new vector.

  def / s
    V[x/s, y/s]
  end

  def == other # :nodoc:
    x == other.x && y == other.y
  end

  ##
  # Return the length of the vector from the origin.

  def magnitude
    Math.sqrt(x*x + y*y)
  end

  def inspect # :nodoc:
    "#{self.class.name}[%.2f, %.2f]" % [x, y]
  end
  alias to_s inspect # :nodoc:
end
