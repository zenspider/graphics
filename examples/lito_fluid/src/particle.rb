class Vec2
  attr_accessor :x, :y
  def initialize x, y
    @x = x
    @y = y
  end

  def + other
    Vec2.new @x+other.x, @y+other.y
  end

  def - other
    Vec2.new @x-other.x, @y-other.y
  end

  def scale s
    Vec2.new @x*s, @y*s
  end

  def * s
    Vec2.new @x*s, @y*s
  end

  def == other
    @x == other.x && @y == other.y
  end

  def magnitude
    Math.sqrt(@x**2 + @y**2)
  end

  def normalize
    m = self.magnitude
    if m == 0
      Vec2.new 0, 0
    else
      Vec2.new @x.to_f/m, @y.to_f/m
    end
  end
end

class Particle
  attr_accessor :density, :position, :velocity,
                :pressure_force, :viscosity_force
  def initialize pos
    # Scalars
    @density = 0

    # Forces
    @position = pos
    @velocity = Vec2.new 0.0, 0.0
    @pressure_force = Vec2.new 0.0, 0.0
    @viscosity_force = Vec2.new 0.0, 0.0
  end
end
