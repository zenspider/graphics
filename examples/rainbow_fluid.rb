require "graphics"
require "graphics/rainbows"

class Float
  ##
  # A floating-point friendly `between?` function that excludes
  # the lower bound.
  # Equivalent to `min < x <= max`
  ##
  def xbetween? min, max
    min < self && self <= max
  end
end

class Particle
  attr_accessor :density, :position, :velocity,
                :pressure_force, :viscosity_force
  def initialize pos
    # Scalars
    @density = 0

    # Forces
    @position        = pos
    @velocity        = V::ZERO
    @pressure_force  = V::ZERO
    @viscosity_force = V::ZERO
  end
end

class SPH
  ##
  # Constants
  #

  MASS          = 5  # Particle mass
  DENSITY       = 1  # Rest density
  GRAVITY       = V[0, -0.5]
  H             = 1  # Smoothing cutoff- essentially, particle size
  K             = 20 # Temperature constant- higher means particle repel more strongly
  ETA           = 1  # Viscosity constant- higher for more viscous

  attr_reader :particles

  def initialize
    # Instantiate particles!
    @particles = []
    (0..10).each do |x|
      (0..10).each do |y|
        jitter = rand * 0.1
        particles << Particle.new(V[x+1+jitter, y+5])
      end
    end
  end

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

  def clear
    # Clear everything
    particles.each do |particle|
      particle.density = DENSITY
      particle.pressure_force = V::ZERO
      particle.viscosity_force = V::ZERO
    end
  end

  def calculate_density
    # TODO: Switch to partitioning for better speed
    # Calculate fluid density around each particle
    particles.each do |particle|
      particles.each do |neighbor|
        # If particles are close together, density increases
        distance = particle.position - neighbor.position

        if distance.magnitude < H then
          # Particles are close enough to matter
          particle.density += MASS * weight(distance, H)
        end
      end
    end
  end

  def calculate_forces
    # Calculate forces on each particle based on density
    particles.each do |particle|
      particles.each do |neighbor|
        distance = particle.position - neighbor.position
        if  distance.magnitude <= H then
          # Temporary terms used to caclulate forces
          density_p = particle.density
          density_n = neighbor.density

          # This *should* never happen, but it's good to check,
          # because we're dividing by density later
          raise "Particle density is, impossibly, 0" unless density_n != 0

          # Pressure derived from the ideal gas law (constant temp)
          pressure_p = K * (density_p - DENSITY)
          pressure_n = K * (density_n - DENSITY)

          # Navier-Stokes equations for pressure and viscosity
          # (ignoring surface tension)
          particle.pressure_force += gradient_weight_spiky(distance, H) *
            (-1.0 * MASS * (pressure_p + pressure_n) / (2 * density_n))

          particle.viscosity_force +=
            (neighbor.velocity - particle.velocity) *
            (ETA * MASS * (1/density_n) * laplacian_weight_viscosity(distance, H))
        end
      end
    end
  end

  def apply_forces delta_time
    # Apply forces to particles- make them move!
    particles.each do |particle|
      total_force = particle.pressure_force + particle.viscosity_force

      # 'Eulerian' style momentum:

      # Calculate acceleration from forces
      acceleration = (total_force * (1.0 / particle.density * delta_time)) + GRAVITY

      # Update position and velocity
      particle.velocity += acceleration * delta_time
      particle.position += particle.velocity * delta_time
    end
  end

  def step delta_time
    clear
    calculate_density
    calculate_forces
    apply_forces delta_time
  end

  ##
  # The walls nudge particles back in-bounds, plus a little jitter
  # so nothing gets stuck
  #

  def make_particles_stay_in_bounds scale
    # TODO: Better boundary conditions (THESE ARE A LAME WORKAROUND)
    particles.each do |particle|
      if particle.position.x >= scale - 0.01
        particle.position.x = scale - (0.01 + 0.1*rand)
        particle.velocity.x = 0
      elsif particle.position.x < 0.01
        particle.position.x = 0.01 + 0.1*rand
        particle.velocity.x = 0
      end

      if particle.position.y >= scale - 0.01
        particle.position.y = scale - (0.01+rand*0.1)
        particle.velocity.y = 0
      elsif particle.position.y < 0.01
        particle.position.y = 0.01 + rand*0.1
        particle.velocity.y = 0
      end
    end
  end
end

class SimulationWindow < Graphics::Simulation
  WINSIZE = 500

  attr_reader :simulation, :s, :spectrum

  DELTA_TIME = 0.1

  def initialize
    super WINSIZE, WINSIZE, "Smoothed Particle Hydrodynamics"
    @simulation = SPH.new
    @scale = 15
    @s = WINSIZE.div @scale
    @spectrum = Graphics::Cubehelix.new
    self.initialize_rainbow spectrum, "cubehelix"
  end

  def update time
    simulation.step DELTA_TIME
    simulation.make_particles_stay_in_bounds @scale
  end

  def draw time
    clear

    simulation.particles.each do |particle|
      pos = particle.position * s
      color = spectrum.clamp(particle.density*30 + 60, 0, 360).to_i

      # Particles
      circle(pos.x, pos.y, 5, "cubehelix_#{color}".to_sym, true)
    end

    fps time
  end
end

SimulationWindow.new.run
