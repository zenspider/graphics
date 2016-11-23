# -*- coding: utf-8 -*-

require "sdl"

class Thingy
  D2R = Math::PI / 180.0

  attr_accessor :screen, :w, :h
  attr_accessor :paused
  attr_accessor :font
  attr_accessor :color, :rgb

  def initialize w, h, c, name
    SDL.init SDL::INIT_VIDEO
    SDL::TTF.init

    self.font = SDL::TTF.open("/System/Library/Fonts/Menlo.ttc", 32, 0)

    SDL::WM.set_caption name, name

    self.screen = SDL::Screen.open w, h, c, SDL::HWSURFACE|SDL::DOUBLEBUF
    self.w, self.h = screen.w, screen.h

    self.color = {}
    self.rgb   = Hash.new { |hash, k| hash[k] = screen.get_rgb(color[k]) }

    register_color :black,     0,   0,   0
    register_color :white,     255, 255, 255
    register_color :red,       255, 0,   0
    register_color :green,     0,   255, 0
    register_color :blue,      0,   0,   255
    register_color :gray,      127, 127, 127
    register_color :yellow,    255, 255, 0

    101.times do |n|
      m = (255 * (n / 100.0)).to_i
      register_color ("gray%02d"  % n).to_sym, m, m, m
      register_color ("red%02d"   % n).to_sym, m, 0, 0
      register_color ("green%02d" % n).to_sym, 0, m, 0
      register_color ("blue%02d"  % n).to_sym, 0, 0, m
    end

    self.paused = false
  end

  def register_color name, r, g, b, a = 255
    color[name] = screen.format.map_rgba r, g, b, a
  end

  def populate klass, n
    n.times.map { klass.new self }
  end

  def handle_event event, n
    exit if SDL::Event::Quit === event
  end

  def handle_keys
    exit                  if SDL::Key.press? SDL::Key::ESCAPE
    exit                  if SDL::Key.press? SDL::Key::Q
    self.paused = !paused if SDL::Key.press? SDL::Key::P
  end

  def run
    self.start_time = Time.now
    n = 0
    event = nil
    loop do
      handle_event event, n while event = SDL::Event.poll
      SDL::Key.scan
      handle_keys

      unless paused then
        update n unless paused

        draw_and_flip n

        n += 1 unless paused
      end
    end
  end

  def draw_and_flip n
    self.draw n
    screen.flip
  end

  def draw n
    raise NotImplementedError, "Subclass Responsibility"
  end

  def update n
    # do nothing
  end

  ### drawing routines:

  ##
  # Clear the whole screen

  def clear c = :black
    fast_rect 0, 0, w, h, c
  end

  ##
  # Draw an antialiased line from x1/y1 to x2/y2 in color c.

  def line x1, y1, x2, y2, c
    screen.draw_line x1, y1, x2, y2, color[c], :antialiased
  end

  ##
  # Draw a horizontal line from x1 to x2 at y in color c.

  def hline y, c, x1 = 0, x2 = h
    line x1, y, x2, y, c
  end

  ##
  # Draw a vertical line from y1 to y2 at y in color c.

  def vline x, c, y1 = 0, y2 = w
    line x, y1, x, y2, c
  end

  def angle x1, y1, a, m, c
    rad = a * D2R

    x2 = x1 + Math.cos(rad) * m
    y2 = y1 - Math.sin(rad) * m

    line x1, y1, x2, y2, c
  end

  ##
  # Draw a rect at x/y with w by h dimensions in color c. Ignores blending.

  def fast_rect x, y, w, h, c
    screen.fill_rect x, y, w, h, color[c]
  end

  ##
  # Draw a point at x/y w/ color c.

  def point x, y, c
    screen[x, y] = color[c]
  end

  ##
  # Draw a rect at x/y with w by h dimensions in color c.

  def rect x, y, w, h, c, fill = false
    screen.draw_rect x, y, w, h, color[c], fill
  end

  ##
  # Draw a circle at x/y with radius r in color c.

  def circle x, y, r, c, fill = false
    screen.draw_circle x, y, r, color[c], fill, :antialiased
  end

  ##
  # Draw a circle at x/y with radiuses w/h in color c.

  def ellipse x, y, w, h, c, fill = false
    screen.draw_ellipse x, y, w, h, color[c], fill, :antialiased
  end

  ##
  # Draw an antialiased curve from x1/y1 to x2/y2 via control points
  # cx1/cy1 & cx2/cy2 in color c.

  def bezier x1, y1, cx1, cy1, cx2, cy2, x2, y2, c, l = 7
    screen.draw_bezier x1, y1, cx1, cy1, cx2, cy2, x2, y2, l, color[c], :antialiased
  end

  ## Text

  ##
  # Return the w/h of the text s in font f.

  def text_size s, f = font
    f.text_size s
  end

  ##
  # Return the rendered text s in color c in font f.

  def render_text s, c, f = font
    f.render_solid_utf8 s, *rgb[c]
  end

  ##
  # Draw text s at x/y in color c in font f.

  def text s, x, y, c, f = font
    f.draw_solid_utf8 screen, s, x, y, *rgb[c]
  end

  def debug fmt, *args
    s = fmt % args
    text s, 10, 50, :white
  end

  attr_accessor :start_time

  def fps n
    secs = Time.now - start_time
    fps = "%5.1f fps" % [n / secs]
    text fps, 10, 10, :green
  end

  ### Blitting Methods:

  ## utilities for later

  # put_pixel(x, y, color)
  # []=(x, y, color)
  # get_pixel(x, y)
  # [](x, y)
  # put(src, x, y) # see blit
  # copy_rect(x,y,w,h)
  # transform_surface(bgcolor,angle,xscale,yscale,flags)

  ##
  # Load an image at path into a new surface.

  def image path
    SDL::Surface.load path
  end

  ##
  # Draw a bitmap at x/y with an angle and optional x/y scale.

  def blit o, x, y, a°, xs=1, ys=1, opt=0
    SDL::Surface.transform_blit o, screen, a°, 1, 1, o.w/2, o.h/2, x, y, opt
  end

  ##
  # Create a new sprite with a given width and height and yield to a
  # block with the new sprite as the current screen. All drawing
  # primitives will work and the resulting surface is returned.

  def sprite w, h
    new_screen = SDL::Surface.new SDL::SWSURFACE, w, h, screen
    old_screen = screen

    self.screen = new_screen
    yield if block_given?

    new_screen
  ensure
    self.screen = old_screen
  end
end

class Body
  D2R = Math::PI / 180.0

  NORMAL = {
           :north => 270,
           :south => 90,
           :east  => 180,
           :west  => 0,
           }

  attr_accessor :x, :y, :a, :ga, :m, :w

  def initialize w
    self.w = w

    self.x, self.y = rand(w.w), rand(w.h)
    self.a = 0.0
    self.ga = 0.0
    self.m = 0.0
  end

  def turn dir
    self.a = (a + dir) % 360.0 if dir
  end

  def move
    rad = a * D2R

    self.x += Math.cos(rad) * m
    self.y -= Math.sin(rad) * m
  end

  def clip
    max_h, max_w = w.h, w.w

    if x < 0 then
      self.x = 0
      return :west
    elsif x > max_w then
      self.x = max_w
      return :east
    end

    if y < 0 then
      self.y = 0
      return :north
    elsif y > max_h then
      self.y = max_h
      return :south
    end

    nil
  end

  def random_angle
    360 * rand
  end

  def random_turn deg
    rand(deg) - (deg/2)
  end

  def clip_off_wall
    if wall = clip then
      normal = NORMAL[wall]
      self.ga = (normal + random_turn(90)).degrees unless (normal - ga).abs < 45
    end
  end

  def bounce
    max_h, max_w = w.h, w.w
    normal = nil

    if x < 0 then
      self.x, normal = 0, 0
    elsif x > max_w then
      self.x, normal = max_w, 180
    end

    if y < 0 then
      self.y, normal = 0, 90
    elsif y > max_h then
      self.y, normal = max_h, 270
    end

    if normal then
      self.a = 2 * normal - 180 - a
      self.m *= 0.8
    end
  end

  def wrap
    max_h, max_w = w.h, w.w

    self.x = max_w if x < 0
    self.y = max_h if y < 0

    self.x = 0 if x > max_w
    self.y = 0 if y > max_h
  end
end

class Trail
  @@c = {}

  attr_accessor :a, :w, :max, :c
  def initialize w, max, color = "green"
    self.w = w
    self.a = []
    self.max = max
    unless @@c[color] then
      @@c[color] ||= max.times.map { |n| ("%s%02d" % [color, n]).to_sym }.reverse
    end
    self.c = @@c[color]
  end

  def draw
    a.reverse.each_cons(2).with_index do |((x1, y1), (x2, y2)), i|
      w.line x1, y1, x2, y2, c[i] || :black
    end
  end

  def << body
    a << [body.x, body.y]
    a.shift if a.size > max
    nil
  end
end

class Integer
  def =~ n # 1 =~ 50 :: 1 in 50 chance
    rand(n) <= (self - 1)
  end
end

class Numeric
  def close_to? n, delta = 0.01
    (self - n).abs < delta
  end

  def degrees
    (self < 0 ? self + 360 : self) % 360
  end

  def relative_angle n, max
    deltaCW = (self - n).degrees
    deltaCC = (n - self).degrees

    return if deltaCC < 0.1 || deltaCW < 0.1

    if deltaCC.abs < max then
      deltaCC
    elsif deltaCW.close_to? 180 then
      [-max, max].sample
    elsif deltaCW < deltaCC then
      -max
    else
      max
    end
  end
end

if $0 == __FILE__ then
  SDL.init SDL::INIT_EVERYTHING
  SDL.set_video_mode(640, 480, 16, SDL::SWSURFACE)
  sleep 1
  puts "if you saw a window, it was working"
end
