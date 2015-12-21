# Simple and fast 2D vector

# require "graphics/xy"
require_relative "./xy"

class Graphics::V

  # degrees to radians
  D2R = Graphics::Simulation::D2R

  # radians to degrees
  R2D = Graphics::Simulation::R2D

  # default initialization vector params
  DEFAULT = { x:0.0, y:0.0, a:0.0, m:0.0 }

  # starting point x coordinate -- preferably float
  attr_accessor :x

  # starting point y coordinate -- preferably float
  attr_accessor :y

  # angle accessor -- in degrees
  attr_accessor :a

  # magnitude accessor (aka velocity)
  attr_accessor :m

  ##
  # A vector is defined by starting point, angle of direction, and magnitude.

  def initialize params = {}
    params = DEFAULT.merge params
    self.x = params[:x]
    self.y = params[:y]
    self.a = params[:a]
    self.m = params[:m]
  end

  ##
  # Starting point as XY.

  def position
    XY[x, y]
  end

  ##
  # Set a new starting point, without modifying anything else.

  def position= new_xy
    self.x, self.y = new_xy.to_a
  end

  ##
  # Vector's axial projection in 2D.

  def dx_dy # :nodoc:
    rad = a * D2R
    dx = Math.cos(rad) * m
    dy = Math.sin(rad) * m
    XY[dx, dy]
  end

  ##
  # Vector's ending Point.

  def endpoint
    position + dx_dy
  end

  ##
  # Set endpoint, keeping starting position and modifying angle and magnitude.

  def endpoint= new_xy
    dxy = new_xy - self.position
    self.a = Math.atan2(dxy.y, dxy.x) * R2D
    self.m = Math.sqrt(dxy.x**2 + dxy.y**2)
  end

  ##
  # Add another vector and return the resulting vector

  def + v2
    cp = self.dup
    cp.endpoint += v2.dx_dy
    cp
  end

  ##
  # Add another vector, modifying self

  def apply v2
    self.endpoint += v2.dx_dy
  end

  ##
  # Return the distance to another vector (starting point), squared.

  def distance_to_squared u
    position.distance_to_squared u.position
  end

  ##
  # Return the angle to another body in degrees.

  def angle_to u
    position.angle_to u.position
  end

  ##
  # Return a random angle 0...360.

  def random_angle
    360 * rand
  end

  ###
  # Randomly turn the vector inside an arc of +deg+ degrees from where
  # it is currently facing.

  def random_turn deg
    rand(deg) - (deg/2)
  end

  ##
  # Turn vector +dir+ degrees.

  def turn dir
    self.a = (a + dir).degrees if dir
  end
end
