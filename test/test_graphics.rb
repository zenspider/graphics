# -*- coding: utf-8 -*-

require "minitest/autorun"

$: << File.expand_path("~/Work/p4/zss/src/minitest-focus/dev/lib")
require "minitest/focus"

require "graphics"

class TestVector < Minitest::Test
  attr_accessor :u

  def setup
    self.u = Graphics::V.new(x:50, y:50, a:0, m:10)
  end

  def test_conversions_vector
    assert_in_delta 50, u.x, 0.001, "x"
    assert_in_delta 50, u.y, 0.001, "y"
    assert_in_delta  0, u.a, 0.001, "angle"
    assert_in_delta 10, u.m, 0.001, "magnitude"
  end

  def test_projection_on_axis
    def assert_vector_projection x, y, u1
      dxy = u1.dx_dy
      assert_in_delta x, dxy.x, 0.001, "m"
      assert_in_delta y, dxy.y, 0.001, "a"
    end

    assert_vector_projection    10,   0, Graphics::V.new(a:0,      m:10)
    assert_vector_projection    10,   0, Graphics::V.new(a:360,    m:10)
    assert_vector_projection    10,   0, Graphics::V.new(a:24*360, m:10)
    assert_vector_projection     0,  10, Graphics::V.new(a:90, m:10)
    assert_vector_projection     0, -10, Graphics::V.new(a:-90, m:10)
    assert_vector_projection     0, -10, Graphics::V.new(a:270, m:10)
    assert_vector_projection (-10),   0, Graphics::V.new(a:180, m:10)
  end

  def test_reset_vector_by_changing_endpoint
    def assert_reset a, m, xy
      u1 = Graphics::V.new
      u1.endpoint = xy
      assert_in_delta a, u1.a, 0.001, 'a'
      assert_in_delta m, u1.m, 0.001, 'm'
    end

    assert_reset      0, 10, XY[10, 0]
    assert_reset     90, 10, XY[0, 10]
    assert_reset  (-90), 10, XY[0, -10]
    assert_reset    180, 10, XY[-10, 0]
    assert_reset    135, Math.sqrt(200), XY[-10, 10]
    assert_reset (-135), Math.sqrt(200), XY[-10, -10]
  end

  def test_random_angle
    srand 42
    assert_in_delta 134.834, u.random_angle
  end

  def test_random_turn
    srand 42
    assert_in_delta 16, u.random_turn(45)
  end

  def test_turn
    assert_in_delta 0, u.a
    u.turn 90
    assert_in_delta 90, u.a
  end

  def test_conversions_readers
    assert_equal XY[50, 50], u.position
    assert_equal 10, u.m
    assert_equal  0, u.a
  end

  def test_change_position
    u.position = XY[50, 40]
    assert_in_delta 50, u.x
    assert_in_delta 40, u.y
    assert_equal 10, u.m
    assert_equal 0, u.a
  end

  def test_push_to_the_right
    u.a = 0
    u.m = 10
    assert_equal XY[50, 50], u.position
    assert_equal XY[60, 50], u.endpoint
  end

  def test_push_up
    u.a = 90
    u.m = 10
    assert_equal XY[50, 50], u.position
    assert_equal XY[50, 60], u.endpoint
  end

  def test_push_to_the_left
    u.a = 180
    u.m = 10
    assert_equal XY[50, 50], u.position
    assert_equal XY[40, 50], u.endpoint
  end

  def test_push_down
    u.a = 270
    u.m = 10
    assert_equal XY[50, 50], u.position
    assert_equal XY[50, 40], u.endpoint
  end

  def test_setting_endpoint_at_0
    u.endpoint = XY[60, 50]
    assert_in_delta 10, u.m, 0.001, "magnitude"
    assert_in_delta 0, u.a, 0.001, "angle"
  end

  def test_setting_endpoint_at_1Q
    u.endpoint = XY[75, 75]
    assert_in_delta 35.355, u.m, 0.001, "magnitude"
    assert_in_delta 45, u.a, 0.001, "angle"
  end

  def test_setting_endpoint_at_90
    u.endpoint = XY[50, 60]
    assert_in_delta 10, u.m, 0.001, "magnitude"
    assert_in_delta 90, u.a, 0.001, "angle"
  end

  def test_setting_endpoint_at_2Q
    u.endpoint = XY[25, 75]
    assert_in_delta 35.355, u.m, 0.001, "magnitude"
    assert_in_delta 135, u.a, 0.001, "angle"
  end

  def test_setting_endpoint_at_180
    u.endpoint = XY[40, 50]
    assert_in_delta 10, u.m, 0.001, "magnitude"
    assert_in_delta 180, u.a, 0.001, "angle"
  end

  def test_setting_endpoint_at_3Q
    u.endpoint = XY[25, 25]
    assert_in_delta 35.355, u.m, 0.001, "magnitude"
    assert_in_delta (-135), u.a, 0.001, "angle"
  end

  def test_setting_endpoint_at_270
    u.endpoint = XY[50, 40]
    assert_in_delta 10, u.m, 0.001, "magnitude"
    assert_in_delta (-90), u.a, 0.001, "angle"
  end

  def test_setting_endpoint_at_4Q
    u.endpoint = XY[75, 25]
    assert_in_delta 35.355, u.m, 0.001, "magnitude"
    assert_in_delta (-45), u.a, 0.001, "angle"
  end

  def test_adding_vectors
    q = Graphics::V.new a:90, m:10

    r = u + q
    assert_equal 45, r.a
    assert_equal Math.sqrt(200), r.m
  end

  def test_add_annulling_vectors
    q = Graphics::V.new a:180, m:10

    r = u + q
    assert_equal 0, r.a
    assert_in_delta 0, r.m, 0.001, "m"
  end

  def test_add_reinforcing_vectors
    u.a = 30
    q = Graphics::V.new a:30, m:10

    r = u + q
    assert_in_delta 30, r.a, 0.001, "a"
    assert_in_delta 20, r.m, 0.001, "m"
  end

  def test_application
    gravity = Graphics::V.new a:270, m:10
    u.apply gravity
    assert_in_delta -45, u.a, 0.001, "a"
  end

end

class TestBody < Minitest::Test
  attr_accessor :w, :b

  FakeSimulation = Struct.new(:w, :h)

  def assert_body x, y, m, a, ga, b
    assert_in_delta x,  b.x,  0.001, "x"
    assert_in_delta y,  b.y,  0.001, "y"
    assert_in_delta a,  b.a,  0.001, "a"
    assert_in_delta m,  b.m,  0.001, "m"
  end

  def setup
    self.w = FakeSimulation.new(100, 100)
    self.b = Graphics::Body.new w

    b.x = 50
    b.y = 50
    b.m = 10
    b.a = 0
  end

  def test_move_right
    assert_body  50, 50, 10, 0, 0, b

    b.move
    assert_body  60, 50, 10, 0, 0, b
  end

  def test_move_bounded_east
    b.x = 99

    b.move_bounded
    assert_body 100, 50, 0, 0, 0, b
  end

  def test_move_bounded_NE
    b.x = b.y = 99
    b.a = 45

    b.move_bounded
    assert_equal XY[100, 100], b.position
    assert_in_delta 0, b.m, 0.001, "resulting magnitude"
  end

  def test_move_bounced
    b.x = 99
    b.m = 10000

    assert_body  99,  50, 10000,  0, 0, b
    b.move_bouncing
    assert b.x < 100
  end

  def test_wrap
    b.x = 99

    assert_body  99, 50, 10, 0, 0, b

    b.move
    b.wrap

    assert_body   0, 50, 10, 0, 0, b # TODO: maybe should be 9?
  end

end

class TestXY < Minitest::Test
  attr_accessor :p

  def setup
    self.p = XY.new 50, 50
  end

  def test_angle_to
    q = XY[0, 0]

    q.x, q.y = 60, 50
    assert_in_epsilon 0, p.angle_to(q)

    q.x, q.y = 50, 40
    assert_in_epsilon 270, p.angle_to(q)

    q.x, q.y = 60, 60
    assert_in_epsilon 45, p.angle_to(q)

    q.x, q.y = 0, 0
    assert_in_epsilon 225, p.angle_to(q)
  end

  def test_distance_to_squared
    q = XY[0, 0]

    q.x, q.y = 60, 50
    assert_in_epsilon 100, p.distance_to_squared(q)

    q.x, q.y = 50, 40
    assert_in_epsilon 100, p.distance_to_squared(q)

    q.x, q.y = 60, 60
    assert_in_epsilon((10*Math.sqrt(2))**2, p.distance_to_squared(q))

    q.x, q.y = 0, 0
    assert_in_epsilon((50*Math.sqrt(2))**2, p.distance_to_squared(q))
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
    exp << [:draw_line, 50, h-50, 60.0, h-50.0, white]

    t.angle 50, 50, 90, 10, :white
    exp << [:draw_line, 50, 49, 50.0, h-60.0, white]

    t.angle 50, 50, 180, 10, :white
    exp << [:draw_line, 50, h-50, 40.0, h-50.0, white]

    t.angle 50, 50, 270, 10, :white
    exp << [:draw_line, 50, h-50, 50.0, h-40.0, white]

    t.angle 50, 50, 45, 10, :white
    d45 = 10 * Math.sqrt(2) / 2
    exp << [:draw_line, 50, h-50, 50+d45, h-50-d45, white]

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

  def test_ellipse
    t.ellipse 0, 0, 25, 25, :white

    h = t.h-1
    exp << [:draw_ellipse, 0, h, 25, 25, t.color[:white]]

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
    exp << [:draw_line, 0, h-42, 100, h-42, t.color[:white]]

    assert_equal exp, t.screen.data
  end

  # def test_image
  #   raise NotImplementedError, 'Need to write test_image'
  # end

  def test_line
    t.line 0, 0, 25, 25, :white
    h = t.h - 1
    exp << [:draw_line, 0, h, 25, h-25, t.color[:white]]

    assert_equal exp, t.screen.data
  end

  def test_point
    skip "not yet"
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
  #
  # def test_render_text
  #   raise NotImplementedError, 'Need to write test_render_text'
  # end
  #
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
  #
  # def test_text_size
  #   raise NotImplementedError, 'Need to write test_text_size'
  # end
  #
  # def test_update
  #   raise NotImplementedError, 'Need to write test_update'
  # end
  #
  # def test_vline
  #   raise NotImplementedError, 'Need to write test_vline'
  # end
end

# require 'graphics/rainbows'
# class TestGraphics < Minitest::Test
#   def setup
#     @t = Graphics::Simulation.new 100, 100, 16, ""
#   end
#
#   def test_registering_rainbows
#     spectrum = Graphics::Hue.new
#     @t.initialize_rainbow spectrum, "spectrum"
#     assert_equal @t.color[:red], @t.color[:spectrum_0]
#     assert_equal @t.color[:green], @t.color[:spectrum_120]
#     assert_equal @t.color[:blue], @t.color[:spectrum_240]
#   end
# end

# class TestTrail < Minitest::Test
#   def test_draw
#     raise NotImplementedError, 'Need to write test_draw'
#   end
#
#   def test_lt2
#     raise NotImplementedError, 'Need to write test_lt2'
#   end
# end
