# -*- coding: utf-8 -*-

require "minitest/autorun"

$: << File.expand_path("~/Work/p4/zss/src/minitest-focus/dev/lib")
require "minitest/focus"

require "thingy"

class TestBody < Minitest::Test
  attr_accessor :w, :b

  FakeThingy = Struct.new(:w, :h)

  def assert_body x, y, m, a, ga, b
    assert_in_delta x,  b.x,  0.001, "x"
    assert_in_delta y,  b.y,  0.001, "y"
    assert_in_delta m,  b.m,  0.001, "m"
    assert_in_delta a,  b.a,  0.001, "a"
    assert_in_delta ga, b.ga, 0.001, "ga"
  end

  def setup
    self.w = FakeThingy.new(100, 100)
    self.b = Body.new w

    b.x = 50
    b.y = 50
    b.m = 10
    b.a = 0
  end

  def test_conversion_sanity
    assert_equal V[50, 50], b.position
    assert_equal V[10, 0], b.velocity

    b.position = V[50, 40]
    assert_in_delta 50, b.x
    assert_in_delta 40, b.y

    b.velocity = V[10, 0]
    assert_in_delta 10, b.m, 0.001, "magnitude"
    assert_in_delta 0, b.a, 0.001, "angle"

    b.velocity = V[0, 10]
    assert_in_delta 10, b.m, 0.001, "magnitude"
    assert_in_delta 90, b.a, 0.001, "angle"

    b.velocity = V[-10, 0]
    assert_in_delta 10, b.m, 0.001, "magnitude"
    assert_in_delta 180, b.a, 0.001, "angle"

    b.velocity = V[0, -10]
    assert_in_delta 10, b.m, 0.001, "magnitude"
    assert_in_delta(-90, b.a, 0.001, "angle")

    b.velocity = V[10, 10]
    assert_in_delta 14.142, b.m, 0.001, "magnitude"
    assert_in_delta 45, b.a, 0.001, "angle"
  end

  def test_conversions
    assert_equal V[50, 50], b.position
    assert_equal V[10, 0], b.velocity

    assert_equal [10, 0], b.m_a
    assert_equal [10, 0], b.dx_dy

    b.position += V[10, 10]

    assert_equal V[60, 60], b.position
    assert_equal V[10, 0], b.velocity

    b.velocity += V[-10, 10]

    assert_equal [10, 90], b.m_a
    p = b.dx_dy
    assert_in_delta 0, p[0]
    assert_in_delta 10, p[1]

    assert_in_delta 90, b.a
    v = b.velocity.to_a
    assert_in_delta 0, v[0]
    assert_in_delta 10, v[1]
  end

  # def test_dx_dy
  #   flunk
  # end

  # def test_m_a
  #   flunk
  # end

  def test_bounce
    b.x = 99
    b.a = 45

    assert_body  99,  50,     10,  45, 0, b

    b.move
    b.bounce

    assert_body  100, 42.929,  8, 135, 0, b
  end

  def test_clip
    b.x = 99

    assert_body  99, 50, 10, 0, 0, b

    b.move
    b.clip

    assert_body 100, 50, 10, 0, 0, b
  end

  def test_clip_off_wall
    b.x = 99

    assert_body 99,  50, 10, 0, 0,   b

    srand 42
    b.move
    b.clip_off_wall

    assert_body 100, 50, 10, 0, 186, b
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

# class TestThingy < Minitest::Test
#   class FakeThingy < Thingy
#     def initialize
#       super 100, 100, 16, "blah"
#
#       s = []
#
#       def s.method_missing(*a)
#         @data ||= []
#         @data << a
#       end
#
#       def s.data
#         @data
#       end
#
#       self.screen = s
#     end
#   end
#
#   attr_accessor :t
#
#   def setup
#     self.t = FakeThingy.new
#   end
#
#   def test_angle
#     raise NotImplementedError, 'Need to write test_angle'
#   end
#
#   def test_bezier
#     raise NotImplementedError, 'Need to write test_bezier'
#   end
#
#   def test_blit
#     raise NotImplementedError, 'Need to write test_blit'
#   end
#
#   def test_circle
#     raise NotImplementedError, 'Need to write test_circle'
#   end
#
#   def test_clear
#     raise NotImplementedError, 'Need to write test_clear'
#   end
#
#   def test_debug
#     raise NotImplementedError, 'Need to write test_debug'
#   end
#
#   def test_draw
#     raise NotImplementedError, 'Need to write test_draw'
#   end
#
#   def test_draw_and_flip
#     raise NotImplementedError, 'Need to write test_draw_and_flip'
#   end
#
#   def test_ellipse
#     t.ellipse 0, 0, 25, 25, :white
#
#     exp = [[:draw_ellipse, 0, 0, 25, 25, t.color[:white], false, :antialiased]]
#     assert_equal exp, t.screen.data
#   end
#
#   def test_fast_rect
#     raise NotImplementedError, 'Need to write test_fast_rect'
#   end
#
#   def test_fps
#     raise NotImplementedError, 'Need to write test_fps'
#   end
#
#   def test_handle_event
#     raise NotImplementedError, 'Need to write test_handle_event'
#   end
#
#   def test_handle_keys
#     raise NotImplementedError, 'Need to write test_handle_keys'
#   end
#
#   def test_hline
#     t.hline 42, :white
#
#     exp = [[:draw_line, 0, 42, 100, 42, t.color[:white], :antialiased]]
#     assert_equal exp, t.screen.data
#   end
#
#   def test_image
#     raise NotImplementedError, 'Need to write test_image'
#   end
#
#   def test_line
#     t.line 0, 0, 25, 25, :white
#
#     exp = [[:draw_line, 0, 0, 25, 25, t.color[:white], :antialiased]]
#     assert_equal exp, t.screen.data
#   end
#
#   def test_point
#     t.point 2, 10, :white
#
#     exp = [nil, nil, t.color[:white]]
#     assert_equal exp, t.screen
#
#     skip "This test isn't sufficient"
#   end
#
#   def test_populate
#     raise NotImplementedError, 'Need to write test_populate'
#   end
#
#   def test_rect
#     raise NotImplementedError, 'Need to write test_rect'
#   end
#
#   def test_register_color
#     raise NotImplementedError, 'Need to write test_register_color'
#   end
#
#   def test_render_text
#     raise NotImplementedError, 'Need to write test_render_text'
#   end
#
#   def test_run
#     raise NotImplementedError, 'Need to write test_run'
#   end
#
#   def test_sprite
#     raise NotImplementedError, 'Need to write test_sprite'
#   end
#
#   def test_text
#     raise NotImplementedError, 'Need to write test_text'
#   end
#
#   def test_text_size
#     raise NotImplementedError, 'Need to write test_text_size'
#   end
#
#   def test_update
#     raise NotImplementedError, 'Need to write test_update'
#   end
#
#   def test_vline
#     raise NotImplementedError, 'Need to write test_vline'
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

# Number of errors detected: 145
