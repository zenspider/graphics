# -*- coding: utf-8 -*-

require "minitest/autorun"
require "graphics"

class TestBody < Minitest::Test
  attr_accessor :w, :b

  FakeSimulation = Struct.new(:w, :h)

  def assert_body x, y, m, a, ga, b
    assert_in_delta x,  b.x,  0.001, "x"
    assert_in_delta y,  b.y,  0.001, "y"
    assert_in_delta m,  b.m,  0.001, "m"
    assert_in_delta a,  b.a,  0.001, "a"
    assert_in_delta ga, b.ga, 0.001, "ga"
  end

  def setup
    self.w = FakeSimulation.new(100, 100)
    self.b = Graphics::Body.new w

    b.x = 50
    b.y = 50
    b.m = 10
    b.a = 0
  end

  def test_conversions_readers
    assert_equal V[50, 50], b.position
    assert_equal V[10, 0], b.velocity
  end

  def test_conversions_pos
    b.position = V[50, 40]
    assert_in_delta 50, b.x
    assert_in_delta 40, b.y
  end

  def test_conversions_vel_0
    b.velocity = V[10, 0]
    assert_in_delta 10, b.m, 0.001, "magnitude"
    assert_in_delta 0, b.a, 0.001, "angle"
    assert_equal V[10, 0], b.velocity
  end

  def test_conversions_vel_90
    b.velocity = V[0, 10]
    assert_in_delta 10, b.m, 0.001, "magnitude"
    assert_in_delta 90, b.a, 0.001, "angle"
  end

  def test_conversions_vel_180
    b.velocity = V[-10, 0]
    assert_in_delta 10, b.m, 0.001, "magnitude"
    assert_in_delta 180, b.a, 0.001, "angle"
  end

  def test_conversions_vel_270
    b.velocity = V[0, -10]
    assert_in_delta 10, b.m, 0.001, "magnitude"
    assert_in_delta(-90, b.a, 0.001, "angle")
  end

  def test_conversions_vel_45
    b.velocity = V[10, 10]
    assert_in_delta 10, b.velocity.x
    assert_in_delta 10, b.velocity.y

    assert_in_delta 14.142, b.m, 0.001, "magnitude"
    assert_in_delta 45, b.a, 0.001, "angle"
  end

  def test_dx_dy
    exp = 14.142

    b.velocity = V[10, 10]

    assert_in_delta 45, b.a
    assert_in_delta exp, b.m

    assert_in_delta 10, b.dx_dy[0]
    assert_in_delta 10, b.dx_dy[1]

    b.a = 45
    b.m = 10

    dx, dy = b.dx_dy

    assert_in_delta exp/2, dx
    assert_in_delta exp/2, dy
  end

  def test_m_a
    b.velocity = V[10, 10]

    assert_in_delta 14.142, b.m
    assert_in_delta 45, b.a

    assert_in_delta 14.142, b.m_a[0]
    assert_in_delta 45, b.m_a[1]
  end

  def test_bounce_east
    b.x = 99
    b.a = 45

    assert_body  99,  50, 10, 45, 0, b

    # dist_to_wall_x = w.w - b.x             :: 1
    # m_over_xy = b.m / Math.sqrt(2)         :: 7.0710678
    # bounce_x = m_over_xy - dist_to_wall_x  :: 6.0710678

    b.move
    b.bounce

    assert_body w.w-6.07106, 57.07106, 8, 135, 0, b
  end

  def test_bounce_west
    b.x = 1
    b.a = 135

    assert_body  1,  50, 10, 135, 0, b

    b.move
    b.bounce

    assert_body 6.07106, w.h-42.929, 8, 45, 0, b
  end

  def test_bounce_north
    b.y = 99
    b.a = 45

    assert_body  50,  99, 10, 45, 0, b

    b.move
    b.bounce

    assert_body 57.071, w.h-6.071, 8, 315, 0, b
  end

  def test_bounce_south
    b.y = 1
    b.a = 315

    assert_body  50, 1, 10, 315, 0, b

    b.move
    b.bounce

    assert_body 57.071, 6.071, 8, 45, 0, b
  end

  def test_clip
    b.x = 99

    assert_body  99, 50, 10, 0, 0, b

    b.move
    b.clip

    assert_body 91, 50, 10, 0, 0, b
  end

  def test_clip_off_wall
    b.x = 99

    assert_body 99,  50, 10, 0, 0,   b

    srand 42
    b.move
    b.clip_off_wall

    assert_body 91, 50, 10, 0, 186, b
  end

  def test_move
    assert_body 50, 50, 10, 0, 0,   b

    b.move

    assert_body 60, 50, 10, 0, 0,   b
  end

  def test_move_by
    assert_body 50, 50, 10, 0, 0,   b

    b.move_by 180, 10

    assert_body 40, 50, 10, 0, 0,   b
  end

  def test_random_angle
    srand 42

    assert_in_delta 134.834, b.random_angle

    assert_body 50, 50, 10, 0, 0, b
  end

  def test_random_turn
    srand 42

    assert_in_delta 16, b.random_turn(45)

    assert_body 50, 50, 10, 0, 0, b
  end

  def test_turn
    assert_body 50, 50, 10,  0, 0, b

    b.turn 90

    assert_body 50, 50, 10, 90, 0, b
  end

  def test_wrap
    b.x = 99

    assert_body  99, 50, 10, 0, 0, b

    b.move
    b.wrap

    assert_body   0, 50, 10, 0, 0, b # TODO: maybe should be 9?
  end

  def test_angle_to
    # b is at 50, 50

    b2 = Graphics::Body.new w

    b2.x, b2.y = 60, 50
    assert_in_epsilon 0, b.angle_to(b2)

    b2.x, b2.y = 50, 40
    assert_in_epsilon 270, b.angle_to(b2)

    b2.x, b2.y = 60, 60
    assert_in_epsilon 45, b.angle_to(b2)

    b2.x, b2.y = 0, 0
    assert_in_epsilon 225, b.angle_to(b2)
  end

  def test_distance_to_squared
    # b is at 50, 50

    b2 = Graphics::Body.new w

    b2.x, b2.y = 60, 50
    assert_in_epsilon 100, b.distance_to_squared(b2)

    b2.x, b2.y = 50, 40
    assert_in_epsilon 100, b.distance_to_squared(b2)

    b2.x, b2.y = 60, 60
    assert_in_epsilon((10*Math.sqrt(2))**2, b.distance_to_squared(b2))

    b2.x, b2.y = 0, 0
    assert_in_epsilon((50*Math.sqrt(2))**2, b.distance_to_squared(b2))
  end
end

class TestInteger < Minitest::Test
  def test_match
    srand 42
    assert_equal [0, 1], 2.times.map { rand(2) }

    srand 42
    assert(1 =~ 2)
    refute(1 =~ 2)
  end
end

class TestNumeric < Minitest::Test
  def test_close_to
    assert_operator 1.0001, :close_to?, 1.0002
    refute_operator 1.0001, :close_to?, 2.0002
  end

  def test_degrees
    assert_equal 1, 361.degrees
    assert_equal 359, -1.degrees
  end

  def test_relative_angle
    assert_equal 10, 0.relative_angle(10, 20)
    assert_equal  5, 0.relative_angle(10,  5)

    assert_equal 180, 180.relative_angle(0, 360)
    assert_equal 185, 0.relative_angle(185, 360) # huh?

    assert_equal(-180, 0.relative_angle(270, 180)) # Huh?
  end
end

class TestSimulation < Minitest::Test
  # make_my_diffs_pretty!

  class FakeSimulation < Graphics::Simulation
    def initialize
      super 100, 100, 16, "blah"

      s = []

      def s.method_missing *a
        @data ||= []
        @data << a
      end

      def s.data
        @data
      end

      self.screen = s
    end
  end

  attr_accessor :t, :white, :exp

  def setup
    self.t = FakeSimulation.new
    self.white = t.color[:white]
    self.exp = []
  end

  def test_angle
    h = t.h-1

    t.angle 50, 50, 0, 10, :white
    exp << [:draw_line, 50, h-50, 60.0, h-50.0, white, 255, true]

    t.angle 50, 50, 90, 10, :white
    exp << [:draw_line, 50, 49, 50.0, h-60.0, white, 255, true]

    t.angle 50, 50, 180, 10, :white
    exp << [:draw_line, 50, h-50, 40.0, h-50.0, white, 255, true]

    t.angle 50, 50, 270, 10, :white
    exp << [:draw_line, 50, h-50, 50.0, h-40.0, white, 255, true]

    t.angle 50, 50, 45, 10, :white
    d45 = 10 * Math.sqrt(2) / 2
    exp << [:draw_line, 50, h-50, 50+d45, h-50-d45, white, 255, true]

    assert_equal exp, t.screen.data
  end

  # def test_bezier
  #   raise NotImplementedError, 'Need to write test_bezier'
  # end
  #
  # def test_blit
  #   raise NotImplementedError, 'Need to write test_blit'
  # end
  #
  # def test_circle
  #   raise NotImplementedError, 'Need to write test_circle'
  # end
  #
  # def test_clear
  #   raise NotImplementedError, 'Need to write test_clear'
  # end
  #
  # def test_debug
  #   raise NotImplementedError, 'Need to write test_debug'
  # end
  #
  # def test_draw
  #   raise NotImplementedError, 'Need to write test_draw'
  # end
  #
  # def test_draw_and_flip
  #   raise NotImplementedError, 'Need to write test_draw_and_flip'
  # end

make_my_diffs_pretty!

  def test_ellipse
    t.ellipse 0, 0, 25, 25, :white

    h = t.h-1
    exp << [:draw_ellipse, 0, h, 25, 25, t.color[:white], 255, true, false]

    assert_equal exp, t.screen.data
  end

  # def test_fast_rect
  #   raise NotImplementedError, 'Need to write test_fast_rect'
  # end
  #
  # def test_fps
  #   raise NotImplementedError, 'Need to write test_fps'
  # end
  #
  # def test_handle_event
  #   raise NotImplementedError, 'Need to write test_handle_event'
  # end
  #
  # def test_handle_keys
  #   raise NotImplementedError, 'Need to write test_handle_keys'
  # end

  def test_hline
    t.hline 42, :white
    h = t.h - 1
    exp << [:draw_line, 0, h-42, 100, h-42, t.color[:white], 255, true]

    assert_equal exp, t.screen.data
  end

  # def test_image
  #   raise NotImplementedError, 'Need to write test_image'
  # end

  def test_line
    t.line 0, 0, 25, 25, :white
    h = t.h - 1
    exp << [:draw_line, 0, h, 25, h-25, t.color[:white], 255, true]

    assert_equal exp, t.screen.data
  end

  def test_point
    t.point 2, 10, :white

    exp = [nil, nil, t.color[:white]]
    assert_equal exp, t.screen

    skip "This test isn't sufficient"
  end

  # def test_populate
  #   raise NotImplementedError, 'Need to write test_populate'
  # end
  #
  # def test_rect
  #   raise NotImplementedError, 'Need to write test_rect'
  # end
  #
  # def test_register_color
  #   raise NotImplementedError, 'Need to write test_register_color'
  # end

  def test_render_text
    skip "not yet"
    assert_equal 42, t.render_text("blah", :black)

    raise NotImplementedError, 'Need to write test_render_text'
  end

  # def test_run
  #   raise NotImplementedError, 'Need to write test_run'
  # end
  #
  # def test_sprite
  #   raise NotImplementedError, 'Need to write test_sprite'
  # end
  #
  # def test_text
  #   raise NotImplementedError, 'Need to write test_text'
  # end

  def test_text_size
    assert_equal [76, 38], t.text_size("blah")
    assert_equal [0, 38], t.text_size("")
    assert_equal [0, 38], t.text_size(:blah)
  end

  # def test_update
  #   raise NotImplementedError, 'Need to write test_update'
  # end
  #
  # def test_vline
  #   raise NotImplementedError, 'Need to write test_vline'
  # end
end

require 'graphics/rainbows'
class TestGraphics < Minitest::Test
  def setup
    @t = Graphics::Simulation.new 100, 100, 16, ""
  end

  def test_registering_rainbows
    spectrum = Graphics::Hue.new
    @t.initialize_rainbow spectrum, "spectrum"
    assert_equal @t.color[:red], @t.color[:spectrum_0]
    assert_equal @t.color[:green], @t.color[:spectrum_120]
    assert_equal @t.color[:blue], @t.color[:spectrum_240]
  end
end

# class TestTrail < Minitest::Test
#   def test_draw
#     raise NotImplementedError, 'Need to write test_draw'
#   end
#
#   def test_lt2
#     raise NotImplementedError, 'Need to write test_lt2'
#   end
# end
