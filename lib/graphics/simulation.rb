# -*- coding: utf-8 -*-

require "sdl"

module SDL; end # :nodoc: -- stupid rdoc :(

##
# A simulation. This ties everything together and provides a bunch of
# convenience methods to make life easier.

class Graphics::Simulation

  # degrees to radians
  D2R = Math::PI / 180.0

  # radians to degrees
  R2D = 1 / D2R

  # The window the simulation is drawing in.
  attr_accessor :screen

  # The window width.
  attr_accessor :w

  # The window height.
  attr_accessor :h

  # Pause the simulation.
  attr_accessor :paused

  # The current font for rendering text.
  attr_accessor :font

  # A hash of color names to their values.

  attr_accessor :color

  # A hash of color values to their rgb values. For text, apparently. *shrug*
  attr_accessor :rgb

  # Number of update iterations per drawing tick
  attr_accessor :iter_per_tick

  ##
  # Create a new simulation of a certain width and height. Optionally,
  # you can set the bits per pixel (0 for current screen settings),
  # the name of the window, and whether or not to run in full screen mode.
  #
  # This also names a bunch colors and hues for convenience.

  def initialize w, h, bpp = 0, name = self.class.name, full = false
    SDL.init SDL::INIT_VIDEO
    SDL::TTF.init

    full = full ? SDL::FULLSCREEN : 0

    self.font = SDL::TTF.open("/System/Library/Fonts/Menlo.ttc", 32, 0)

    SDL::WM.set_caption name, name

    self.screen = SDL::Screen.open w, h, bpp, SDL::HWSURFACE|SDL::DOUBLEBUF|full
    self.w, self.h = screen.w, screen.h

    self.color = {}
    self.rgb   = Hash.new { |hash, k| hash[k] = screen.get_rgb(color[k]) }
    self.paused = false

    self.iter_per_tick = 1

    initialize_colors
  end

  def initialize_colors
    register_color :black,     0,   0,   0
    register_color :white,     255, 255, 255
    register_color :red,       255, 0,   0
    register_color :green,     0,   255, 0
    register_color :blue,      0,   0,   255
    register_color :gray,      127, 127, 127
    register_color :yellow,    255, 255, 0
    register_color :alpha,     0, 0, 0, 0

    (0..99).each do |n|
      m = (255 * (n / 100.0)).to_i
      register_color(("gray%02d"  % n).to_sym, m, m, m)
      register_color(("red%02d"   % n).to_sym, m, 0, 0)
      register_color(("green%02d" % n).to_sym, 0, m, 0)
      register_color(("blue%02d"  % n).to_sym, 0, 0, m)
    end
  end

  ##
  # Name a color w/ rgba values.

  def register_color name, r, g, b, a = 255
    color[name] = screen.format.map_rgba r, g, b, a
  end

  ##
  # Return an array populated by instances of +klass+. You can specify
  # how many to create here or it will access +klass::COUNT+ as the
  # default.

  def populate klass, n = klass::COUNT
    n.times.map {
      o = klass.new self
      yield o if block_given?
      o
    }
  end

  ##
  # Handle an event. By default only handles the Quit event. Override
  # if you want to add more handlers. Be sure to call super or you
  # won't be able to quit.

  def handle_event event, n
    exit if SDL::Event::Quit === event
  end

  ##
  # Handle key events. By default handles ESC & Q (quit) and P
  # (pause). Override this if you want to handle more key events. Be
  # sure to call super or provide your own means of quitting and/or
  # pausing.

  def handle_keys
    exit                  if SDL::Key.press? SDL::Key::ESCAPE
    exit                  if SDL::Key.press? SDL::Key::Q

    self.iter_per_tick += 1 if SDL::Key.press? SDL::Key::SLASH
    self.iter_per_tick -= 1 if SDL::Key.press? SDL::Key::MINUS
    self.iter_per_tick = 1 if iter_per_tick < 1

    self.paused = !paused if SDL::Key.press? SDL::Key::P
  end

  ##
  # Run the simulation. This handles all events by polling and
  # scanning for key presses (multiple keys at once are possible).
  #
  # On each tick, call update, then draw the scene.

  def run
    self.start_time = Time.now
    n = 0
    event = nil

    loop do
      handle_event event, n while event = SDL::Event.poll
      SDL::Key.scan
      handle_keys

      next if paused

      iter_per_tick.times { |i| update n; n += 1 }
      draw_and_flip n
    end
  end

  def draw_and_flip n # :nodoc:
    self.draw n
    screen.flip
  end

  ##
  # Draw the scene. This is a subclass responsibility and must draw
  # the entire window (including calling clear).

  def draw n
    raise NotImplementedError, "Subclass Responsibility"
  end

  ##
  # Update the simulation. This does nothing by default and must be
  # overridden by the subclass.

  def update n
    # do nothing
  end

  ##
  # Clear the whole screen

  def clear c = :black
    fast_rect 0, 0, w, h, c
  end

  ##
  # Draw an antialiased line from x1/y1 to x2/y2 in color c.

  def line x1, y1, x2, y2, c
    h = self.h
    screen.draw_line x1, h-y1-1, x2, h-y2-1, color[c], :antialiased
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
  # Draw a closed form polygon from an array of points in a particular
  # color.

  def polygon *points, color
    points << points.first
    points.each_cons(2) do |p1, p2|
      w.line(*p1, *p2, color)
    end
  end

  ##
  # Draw a line from x1/y1 to a particular magnitude and angle in color c.

  def angle x1, y1, a, m, c
    x2, y2 = project x1, y1, a, m
    line x1, y1, x2, y2, c
  end

  ##
  # Draw a rect at x/y with w by h dimensions in color c. Ignores blending.

  def fast_rect x, y, w, h, c
    screen.fill_rect x, self.h-y-h, w, h, color[c]
  end

  ##
  # Draw a point at x/y w/ color c.

  def point x, y, c
    screen[x, h-y] = color[c]
  end

  ##
  # Calculate the x/y coordinate offset from x1/y1 with an angle and a
  # magnitude.

  def project x1, y1, a, m
    rad = a * D2R
    [x1 + Math.cos(rad) * m, y1 + Math.sin(rad) * m]
  end

  ##
  # Draw a rect at x/y with w by h dimensions in color c.

  def rect x, y, w, h, c, fill = false
    screen.draw_rect x, self.h-y-h, w, h, color[c], fill
  end

  ##
  # Draw a circle at x/y with radius r in color c.

  def circle x, y, r, c, fill = false
    screen.draw_circle x, h-y, r, color[c], fill, :antialiased
  end

  ##
  # Draw a circle at x/y with radiuses w/h in color c.

  def ellipse x, y, w, h, c, fill = false
    screen.draw_ellipse x, self.h-y, w, h, color[c], fill, :antialiased
  end

  ##
  # Draw an antialiased curve from x1/y1 to x2/y2 via control points
  # cx1/cy1 & cx2/cy2 in color c.

  def bezier x1, y1, cx1, cy1, cx2, cy2, x2, y2, c, l = 7
    h = self.h
    screen.draw_bezier x1, h-y1, cx1, h-cy1, cx2, h-cy2, x2, h-y2, l, color[c], :antialiased
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
    f.draw_solid_utf8 screen, s, x, self.h-y-f.height, *rgb[c]
  end

  ##
  # Print out some extra debugging information underneath the fps line
  # (if any).

  def debug fmt, *args
    s = fmt % args
    text s, 10, h-40-font.height, :white
  end

  attr_accessor :start_time # :nodoc:

  ##
  # Draw the current frames-per-second in the top left corner in green.

  def fps n
    secs = Time.now - start_time
    fps = "%5.1f fps" % [n / secs]
    text fps, 10, h-font.height, :green
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
  # Return the current mouse state: x, y, buttons.

  def mouse
    r = SDL::Mouse.state
    r[1] = h-r[1]
    r
  end

  ##
  # Draw a bitmap at x/y with an angle and optional x/y scale.

  def blit o, x, y, a°, xs = 1, ys = 1, opt = 0
    SDL::Surface.transform_blit o, screen, -a°, 1, 1, o.w/2, o.h/2, x, h-y, opt
  end

  ##
  # Create a new sprite with a given width and height and yield to a
  # block with the new sprite as the current screen. All drawing
  # primitives will work and the resulting surface is returned.

  def sprite w, h
    new_screen = SDL::Surface.new SDL::SWSURFACE, w, h, screen
    old_screen = screen
    old_w, old_h = self.w, self.h
    self.w, self.h = w, h

    self.screen = new_screen
    yield if block_given?

    new_screen.set_color_key SDL::SRCCOLORKEY, 0

    new_screen
  ensure
    self.screen = old_screen
    self.w, self.h = old_w, old_h
  end
end

if $0 == __FILE__ then
  SDL.init SDL::INIT_EVERYTHING
  SDL.set_video_mode(640, 480, 16, SDL::SWSURFACE)
  sleep 1
  puts "if you saw a window, it was working"
end
