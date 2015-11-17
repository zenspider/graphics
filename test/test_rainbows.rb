require 'minitest/autorun'
require 'graphics'
require 'graphics/rainbows'

class RainbowsTest < Minitest::Test

  def setup
    @greyscale = Graphics::Greyscale.new
    @hue = Graphics::Hue.new
    @cubehelix = Graphics::Cubehelix.new
  end

  def test_clamping
    assert_equal 360, @hue.clamp(10000, 0, 360)
    assert_equal 0,   @hue.clamp(-20, 0, 360)
  end

  def test_scaling_clamps_values
    assert_equal 360, @hue.scale(10000, 0, 360)
    assert_equal 0,   @hue.scale(-20, 0, 360)
  end

  def test_scaling
    # (We use assert_same instead of _equal to make sure we're
    # really getting integers back)
    assert_same 0,   @hue.scale(0, 0, 360)
    assert_same 180, @hue.scale(180, 0, 360)
    assert_same 360, @hue.scale(360, 0, 360)
    assert_same 30,  @hue.scale(30, 0, 360)
    # From smaller ranges
    assert_same 0,   @hue.scale(0, 180, 360)
    assert_same 180, @hue.scale(50, 0, 100)
    # From larger ranges
    assert_same 180, @hue.scale(400, 100, 900)
  end

  def test_greyscale
    assert_equal [0, 0, 0],       @greyscale.color(0)# Black
    assert_equal [127, 127, 127], @greyscale.color(180) # Mid-grey
    assert_equal [255, 255, 255], @greyscale.color(360) # White
  end

  def test_rainbow_start_and_end
    # Half a greyscale spectrum
    assert_equal [127, 127, 127], @greyscale.color(50, 0, 100)
    assert_equal [255, 255, 255], @greyscale.color(1000, 0, 100)
  end

  def test_hue
    assert_equal [255, 0, 0],   @hue.color(0)   # Red
    assert_equal [255, 127, 0], @hue.color(30)  # Orange
    assert_equal [255, 255, 0], @hue.color(60)  # Yellow
    assert_equal [0, 255, 0],   @hue.color(120) # Green
    assert_equal [0, 255, 255], @hue.color(180) # Cyan
    assert_equal [0, 0, 255],   @hue.color(240) # Blue
    assert_equal [255, 0, 255], @hue.color(300) # Magenta
    assert_equal [255, 0, 0],   @hue.color(360) # Red
  end

  def test_cubehelix
    # Cubehelix reference values from James Davenport's Python implementation
    # Using:
    # start       = 0.5
    # rotations   = -1.5
    # saturation  = 1.2
    # gamma       = 1.0
    # NOTE(Lito): These values are slightly different from my Ruby
    # implementation. This could be floating-point error, or because
    # cubehelix uses a slightly different scale (1-256 vs 0-360).
    reference_values = [[0.0, 0.0, 0.0],                              # 0
    [0.052086060929534689, 0.34174526961141383, 0.30658807547214501], # 90
    [0.65901854013946559, 0.46936557468373608, 0.24845035363356044],  # 180
    [0.78295958648052344, 0.69774239781785263, 0.96714049479106534],  # 270
    [1.0, 1.0, 1.0]]                                                  # 360
    # Move the colors from 0-1 scale to a 0-255 scale
    rgb_255_reference = reference_values.map do |rgb|
      rgb.map do |color|
        (color*255).round
      end
    end

    def assert_arr_in_delta exp, act, delta
      exp.zip(act) do |e, a|
        assert_in_delta e, a, delta
      end
    end

    assert_arr_in_delta rgb_255_reference[0], @cubehelix.color(0),   2
    assert_arr_in_delta rgb_255_reference[1], @cubehelix.color(90),  2
    assert_arr_in_delta rgb_255_reference[2], @cubehelix.color(180), 2
    assert_arr_in_delta rgb_255_reference[3], @cubehelix.color(270), 2
    assert_arr_in_delta rgb_255_reference[4], @cubehelix.color(360), 2

  end
end
