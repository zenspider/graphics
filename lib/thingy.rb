# -*- coding: utf-8 -*-

require "sdl"

class Thingy
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

    self.paused = false
  end

  def register_color name, r, g, b, a = 255
    color[name] = screen.format.map_rgba r, g, b, a
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

  def load path
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
