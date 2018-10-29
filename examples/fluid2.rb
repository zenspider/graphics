require "graphics"

class Particle < Graphics::Body
  MASS       = 5          # Particle mass
  DENSITY    = 1          # Rest density
  GRAVITY    = V[0, -0.5] #
  H          = 1          # Smoothing cutoff: essentially, particle size
  K          = 20         # Temperature constant: higher repels more strongly
  ETA        = 1          # Viscosity constant: higher for more viscous
  DELTA_TIME = 0.1        #

  attr_accessor :density, :pressure_force, :viscosity_force, :s
  attr_writer :nearby

  def initialize w, x, y, s
    super w
    self.x = x
    self.y = y
    self.s = s
    self.nearby = nil

    clear
  end

  class View
    def self.draw w, b
      s, a, m, d = b.s, b.a, b.m, b.density
      x = b.x * s
      y = b.y * s

      w.circle(x, y, d, :gray)
      w.circle(x, y, 5, :white)

      w.angle x, y, a, m * s, :red
    end
  end

  def clear
    self.nearby          = nil
    self.density         = DENSITY
    self.pressure_force  = V::ZERO
    self.viscosity_force = V::ZERO
  end

  def nearby
    @nearby ||= begin
                  p = self.position
                  w.particles.find_all { |neighbor|
                    (p - neighbor.position).magnitude < H
                  }
                end
  end

  def calculate_density
    nearby.each do |neighbor|
      distance = (position - neighbor.position)

      self.density += MASS * weight(distance, H)
    end
  end

  def calculate_forces
    particle = self
    nearby.each do |neighbor|
      distance = (particle.position - neighbor.position)

      # Temporary terms used to caclulate forces
      density_p = particle.density
      density_n = neighbor.density

      # This *should* never happen, but it's good to check, because
      # we're dividing by density later
      raise "Particle density is, impossibly, 0" unless density_n != 0

      # Pressure derived from the ideal gas law (constant temp)
      pressure_p = K * (density_p - DENSITY)
      pressure_n = K * (density_n - DENSITY)

      # Navier-Stokes equations for pressure and viscosity
      # (ignoring surface tension)
      particle.pressure_force += gradient_weight_spiky(distance, H) *
        (-1.0 * MASS * (pressure_p + pressure_n) / (2 * density_n))

      particle.viscosity_force += (neighbor.velocity - particle.velocity) *
        (ETA * MASS * (1/density_n) * laplacian_weight_viscosity(distance, H))
    end
  end

  def apply_forces
    particle = self
    total_force = particle.pressure_force + particle.viscosity_force

    # 'Eulerian' style momentum:

    # Calculate acceleration from forces
    acceleration = (total_force * (1.0 / particle.density * DELTA_TIME)) + GRAVITY

    # Update position and velocity
    particle.velocity += acceleration * DELTA_TIME
    particle.position += particle.velocity * DELTA_TIME

    limit
  end

  E = 0.01

  def limit width = 15
    if x >= width - E
      self.x = width - (E + 0.1*rand)
      self.m = 0
    elsif x < E
      self.x = E + 0.1*rand
      self.m = 0
    end

    if y >= width - E
      self.y = width - (E+rand*0.1)
      self.m = 0
    elsif y < E
      self.y = E + rand*0.1
      self.m = 0
    end
  end

  ######################################################################
  # Helpers

  ##
  # A weighting function (kernel) for the contribution of each neighbor
  # to a particle's density. Forms a nice smooth gradient from the center
  # of a particle to H, where it's 0
  #

  def weight r, h
    len_r = r.magnitude

    if len_r.xbetween? 0, h
      315.0 / (64 * Math::PI * h**9) * (h**2 - len_r**2)**3
    else
      0.0
    end
  end

  ##
  # Gradient ( that is, V(dx, dy) ) of a weighting function for
  # a particle's pressure. This weight function is spiky (not flat or
  # smooth at x=0) so particles close together repel strongly.
  #

  def gradient_weight_spiky r, h
    len_r = r.magnitude

    if len_r.xbetween? 0, h
      r * (45.0 / (Math::PI * h**6 * len_r)) * (h - len_r)**2 * (-1.0)
    else
      V::ZERO
    end
  end

  ##
  # The laplacian of a weighting function that tends towards infinity when
  # approching 0 (slows down particles moving faster than their neighbors)
  #

  def laplacian_weight_viscosity r, h
    len_r = r.magnitude

    if len_r.xbetween? 0, h
      45.0 / (2 * Math::PI * h**5) * (1 - len_r / h)
    else
      0.0
    end
  end
end

class Float
  def xbetween? min, max
    min < self && self <= max
  end
end

class FluidDynamics2 < Graphics::Simulation
  include ShowFPS

  WINSIZE = 500
  SCALE = 15
  S = WINSIZE / SCALE

  attr_accessor :particles, :scale

  def initialize
    super WINSIZE, WINSIZE, "Smoothed Particle Hydrodynamics"

    self.particles = []
    self.scale = SCALE

    # Instantiate particles!
    (0..10).each do |x|
      (0..10).each do |y|
        jitter = rand * 0.1

        particles << Particle.new(self, x + 1 + jitter, y + 5, S)
      end
    end

    register_bodies particles
  end

  def update n
    particles.each(&:clear)
    particles.each(&:calculate_density)
    particles.each(&:calculate_forces)
    particles.each(&:apply_forces)
  end
end

FluidDynamics2.new.run
