class Graphics::Rainbow
  attr_reader :cache

  def initialize
    @cache = self.cache_colors
  end

  def clamp d, min, max
    [[min, d].max, max].min
  end

  ##
  # Takes a value and a range,
  # and scales that range to 0-360
  def scale d, min, max
    range = max - min
    if range != 0
      scaled = (d.to_f / range) * 360
      return clamp(scaled, 0, 360).round
    else
      0
    end
  end

  def cache_colors
    # Saves all the colors to a hash
    cache = {}
    (0..360).each do |degree|
      cache[degree] = _color degree
    end
    cache
  end

  def color d, min=0, max=360
    scaled = scale d, min, max
    @cache[scaled]
  end

  def _color degree
    raise "Subclass responsibility"
  end
  private :_color
end

##
# Black to white gradient
#
class Graphics::Greyscale < Graphics::Rainbow
  def initialize
    super
  end

  def _color degree
    brightness_unit = degree/360.0
    brightness = (brightness_unit*255.0).floor # Scale back to RGB

    [brightness, brightness, brightness]
  end
end

##
# The full RGB spectrum
#
class Graphics::Hue < Graphics::Rainbow

  def initialize
    super
  end

  def _color degree
    main_color = 1 * 255 # Let chroma (saturation * brightness) always == 1
    second_strongest_color = ((1 - (degree/60.0 % 2 - 1).abs) * 255).floor

    case degree
    when 0..60
      [main_color, second_strongest_color, 0]
    when 61..120
      [second_strongest_color, main_color, 0]
    when 121..180
      [0, main_color, second_strongest_color]
    when 181..240
      [0, second_strongest_color, main_color]
    when 241..300
      [second_strongest_color, 0, main_color]
    when 301..360
      [main_color, 0, second_strongest_color]
    end
  end
end


##
# Spectrum with linearly increasing brightness
#
class Graphics::Cubehelix < Graphics::Rainbow

  def initialize
    super
  end

  def _color degree
    d = degree/360.0
    start = 0.5 # Starting position in color space - 0=blue, 1=red, 2=green
    rotations = -1.5 # How many rotations through the rainbow?
    saturation = 1.2
    gamma = 1.0
    fract = d**gamma # Position on the spectrum

    # Amplitude of the helix
    amp = saturation * fract * (1 - fract) / 2.0
    angle = 2*Math::PI*(start/3.0 + 1.0 + rotations*fract)
    # From the CubeHelix Equations
    r = fract + amp * (-0.14861 * Math.cos(angle) + 1.78277 * Math.sin(angle))
    g = fract + amp * (-0.29227 * Math.cos(angle) - 0.90649 * Math.sin(angle))
    b = fract + amp * (1.97294 * Math.cos(angle))

    [(r * 255).round, (g * 255).round, (b * 255).round]
  end
end

class Graphics::Simulation
  def initialize_rainbow rainbow, name
    rainbow.cache.each do |degree, color|
      color_name = "#{name}_#{degree}".to_sym
      self.register_color(color_name, *color, 255)
    end
  end
end
