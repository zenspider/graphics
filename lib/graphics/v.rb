class V
  attr_accessor :x, :y

  class << self
    alias :[] :new
  end

  def initialize x, y
    @x = x
    @y = y
  end

  ZERO = V[0.0, 0.0]
  ONE  = V[1.0, 1.0]

  def + v
    V[x+v.x, y+v.y]
  end

  def - v
    V[x-v.x, y-v.y]
  end

  def * s
    V[x*s, y*s]
  end

  def / s
    V[x/s, y/s]
  end

  def == other
    x == other.x && y == other.y
  end

  def magnitude
    Math.sqrt(x*x + y*y)
  end

  def inspect
    "#{self.class.name}[%.2f, %.2f]" % [x, y]
  end
  alias to_s inspect
end
