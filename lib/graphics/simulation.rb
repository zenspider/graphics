# -*- coding: utf-8 -*-

require "sdl/sdl"

module SDL
  init INIT_EVERYTHING
end

##
# An abstract simulation. See Graphics::Simulation and Graphics::Drawing.

class Graphics::AbstractSimulation

  # The default color to clear the screen.
  CLEAR_COLOR = :black

  # degrees to radians
  D2R = Math::PI / 180.0

  # radians to degrees
  R2D = 1 / D2R

  # Call +log+ every N ticks, if +log+ is defined.
  LOG_INTERVAL = 60

  # The default font. Menlo on OS X, Deja Vu Sans Mono on linux.
  DEFAULT_FONT = case RUBY_PLATFORM
                 when /darwin/ then "Menlo"
                 when /linux/  then "DejaVuSansMono"
                 else
                   raise "Unsupported platform #{RUBY_PLATFORM}. Please fix."
                 end

  # Collection of collections of Bodies to auto-update and draw.
  attr_accessor :_bodies

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

  # A hash of color values to their rgba values. For text, apparently. *shrug*
  attr_accessor :rgba # TODO: remove?

  # Number of update iterations per drawing tick.
  attr_accessor :iter_per_tick

  # Procs registered to handle key events.
  attr_accessor :key_handler

  # Procs registered to handle keydown events.
  attr_accessor :keydown_handler

  # Is the application done?
  attr_accessor :done

  ##
  # Create a new simulation of a certain width and height. Optionally,
  # you can set the bits per pixel (0 for current screen settings),
  # the name of the window, and whether or not to run in full screen mode.
  #
  # This also names a bunch colors and hues for convenience.

  def initialize w=nil, h=nil, name=self.class.name, full=false
    w ||= SDL::Screen::W/2
    h ||= SDL::Screen::H/2

    # TODO: remove for 1.0.0 final
    raise "Do NOT pass bpp to Simulation anymore" if !name || Integer === name

    full = full ? SDL::FULLSCREEN : 0

    self._bodies = []

    self.font = find_font(DEFAULT_FONT, 32)

    name ||= "Unknown"
    name = name.gsub(/[A-Z]/, ' \0').strip

    self.screen = SDL::Screen.open w, h, 32, self.class::SCREEN_FLAGS|full
    self.w, self.h = w, h # screen.w, screen.h

    screen.title = name

    self.color = {}
    self.rgba  = Hash.new { |hash, k| hash[k] = screen.format.get_rgba(color[k]) }
    self.paused = false

    self.iter_per_tick = 1

    self.key_handler = []
    self.keydown_handler = {}

    initialize_keys
    initialize_colors
  end

  ##
  # Register default key events. Handles ESC & Q (quit) and P (pause).

  def initialize_keys
    add_keydown_handler("\e") { self.done = true }
    add_keydown_handler("q")  { self.done = true }
    add_keydown_handler("p")  { self.paused = !paused }
    add_keydown_handler("/")  { self.iter_per_tick += 1 }
    add_keydown_handler("-")  { self.iter_per_tick -= 1; self.iter_per_tick = 1  if iter_per_tick < 1 }
  end

  def initialize_colors # :nodoc:
    register_color :black,     0,   0,   0
    register_color :white,     255, 255, 255
    register_color :gray,      127, 127, 127
    register_color :red,       255, 0,   0
    register_color :green,     0,   255, 0
    register_color :blue,      0,   0,   255
    register_color :cyan,      0, 255, 255
    register_color :magenta,   255, 0, 255
    register_color :yellow,    255, 255, 0
    register_color :alpha,     0, 0, 0, 0

    (0..99).each do |n|
      m = (255 * (n / 100.0)).to_i
      register_color(("gray%02d"  % n).to_sym, m, m, m)
      register_color(("red%02d"   % n).to_sym, m, 0, 0)
      register_color(("green%02d" % n).to_sym, 0, m, 0)
      register_color(("blue%02d"  % n).to_sym, 0, 0, m)
      register_color(("cyan%02d"    % n).to_sym, 0, m, m)
      register_color(("magenta%02d" % n).to_sym, m, 0, m)
      register_color(("yellow%02d"  % n).to_sym, m, m, 0)
    end

    (0...256).each do |n|
      m = (256 * n / 255.0).to_i
      register_color(("gray%03d"    % n).to_sym, m, m, m)
      register_color(("red%03d"     % n).to_sym, m, 0, 0)
      register_color(("green%03d"   % n).to_sym, 0, m, 0)
      register_color(("blue%03d"    % n).to_sym, 0, 0, m)
      register_color(("cyan%03d"    % n).to_sym, 0, m, m)
      register_color(("magenta%03d" % n).to_sym, m, 0, m)
      register_color(("yellow%03d"  % n).to_sym, m, m, 0)
    end
  end

  font_dirs = [
    # OS X
    "/System/Library/Fonts",
    "/Library/Fonts",
    File.expand_path("~/Library/Fonts/"),

    # Ubuntu
    "/usr/share/fonts/truetype/**/",
  ]
  FONT_GLOB = "{#{font_dirs.join(",")}}" # :nodoc:

  ##
  # Find and open a (TTF) font. Should be as system agnostic as possible.

  def find_font name, size = 16
    font = Dir["#{FONT_GLOB}/#{name}.{ttc,ttf}"].first

    raise ArgumentError, "Can't find font named '#{name}'" unless font

    SDL::TTF.open(font, size)
  end

  ##
  # Register a collection of bodies to be auto-updated and drawn.

  def register_bodies ary
    _bodies << ary
    ary
  end

  ##
  # Register a single Body to be auto-updated and drawn.

  def register_body obj
    _bodies << [obj]
    obj
  end

  ##
  # Name a color w/ rgba values.

  def register_color name, r, g, b, a = 255
    color[name] = screen.format.map_rgba r, g, b, a
  end

  ##
  # Name a color w/ HSL values.

  def register_hsla n, h, s, l, a = 1.0
    register_color n, *from_hsl(h, s, l), (a*255).round
  end

  ##
  # Name a color w/ HSV values.

  def register_hsva n, h, s, v, a = 1.0
    register_color n, *from_hsv(h, s, v), (a*255).round
  end

  ##
  # Convert HSL to RGB.
  #
  # https://en.wikipedia.org/wiki/HSL_and_HSV#From_HSV

  def from_hsl h, s, l # 0..360, 0..1, 0..1
    raise ArgumentError, "%f, %f, %f out of range" % [h, s, v] unless
      h.between?(0, 360) && s.between?(0, 1) && l.between?(0, 1)

    c  = (1 - (2*l - 1).abs) * s
    h2 = h / 60.0
    x  = c * (1 - (h2 % 2 - 1).abs)
    m  = l - c/2

    r, g, b = case
              when 0 <= h2 && h2 < 1 then [c+m, x+m, 0+m]
              when 1 <= h2 && h2 < 2 then [x+m, c+m, 0+m]
              when 2 <= h2 && h2 < 3 then [0+m, c+m, x+m]
              when 3 <= h2 && h2 < 4 then [0+m, x+m, c+m]
              when 4 <= h2 && h2 < 5 then [x+m, 0+m, c+m]
              when 5 <= h2 && h2 < 6 then [c+m, 0+m, x+m]
              else
                raise [h, s, v, h2, x, m].inspect
              end

    [(r*255).round, (g*255).round, (b*255).round]
  end

  ##
  # Convert HSV to RGB.
  #
  # https://en.wikipedia.org/wiki/HSL_and_HSV#From_HSV

  def from_hsv h, s, v # 0..360, 0..1, 0..1
    raise ArgumentError, "%f, %f, %f out of range" % [h, s, v] unless
      h.between?(0, 360) && s.between?(0, 1) && v.between?(0, 1)

    c  = v * s
    h2 = h / 60.0
    x  = c * (1 - (h2 % 2 - 1).abs)
    m  = v - c

    r, g, b = case
              when 0 <= h2 && h2 < 1 then [c+m, x+m, 0+m]
              when 1 <= h2 && h2 < 2 then [x+m, c+m, 0+m]
              when 2 <= h2 && h2 < 3 then [0+m, c+m, x+m]
              when 3 <= h2 && h2 < 4 then [0+m, x+m, c+m]
              when 4 <= h2 && h2 < 5 then [x+m, 0+m, c+m]
              when 5 <= h2 && h2 < 6 then [c+m, 0+m, x+m]
              else
                raise [h, s, v, h2, x, m].inspect
              end

    [(r*255).round, (g*255).round, (b*255).round]
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
    case event
    when SDL::Event::Quit then
      exit
    when SDL::Event::Keydown then
      c = event.sym.chr rescue nil
      b = keydown_handler[c]
      b[self] if b
    end
  end

  ##
  # Register a block to run for a particular key-press. This allows
  # you to register multiple blocks for the same key and also to
  # handle multiple keys down at the same time.

  def add_key_handler k, remove = nil, &b
    k = SDL::Key.const_get k
    key_handler.delete_if { |a, _| k==a } if remove
    key_handler.unshift [k, b]
  end

  ##
  # Register a block to run for a particular keydown event. This is a
  # single key handler per tick and only on a key-down event.

  def add_keydown_handler k, &b
    keydown_handler[k] = b
  end

  ##
  # Handle key events by looking through key_handler and running any
  # blocks that match the key(s) being pressed.

  def handle_keys
    SDL::Key.scan
    key_handler.each do |k, blk|
      blk[self] if SDL::Key.press? k
    end
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
    self.done = false

    logger = respond_to? :log
    log_interval = self.class::LOG_INTERVAL

    loop do
      handle_event event, n while event = SDL::Event.poll
      handle_keys

      next if paused

      iter_per_tick.times { update n; n += 1 }
      draw_and_flip n

      log if logger and n % log_interval == 0

      break if done
    end
  end

  def draw_and_flip n # :nodoc:
    self.draw n
    screen.flip
  end

  ##
  # Draw the scene by clearing the window and drawing all registered
  # bodies. You are free to completely override this or call super and
  # add any extras at the end.

  def draw n
    pre_draw n
    post_draw n
  end

  def pre_draw n
    clear
  end

  def post_draw n
    _bodies.each do |ary|
      draw_collection ary
    end
  end

  ##
  # Draw a homogeneous collection of bodies. This assumes that the MVC
  # pattern described on this class is being used.

  def draw_collection ary
    return if ary.empty?

    cls = ary.first.class.const_get :View

    ary.each do |obj|
      cls.draw self, obj
    end
  end

  ##
  # Update the simulation by telling all registered bodies to update.
  # You are free to completely override this or call super and add any
  # extras at the end.

  def update n
    _bodies.each do |ary|
      ary.each(&:update)
    end
  end

  ##
  # Clear the whole screen. Defaults to CLEAR_COLOR.

  def clear c = self.class::CLEAR_COLOR
    fast_rect 0, 0, w, h, c
  end

  ##
  # Draw an antialiased line from x1/y1 to x2/y2 in color c.

  def line x1, y1, x2, y2, c, aa = true
    h = self.h
    screen.draw_line x1, h-y1-1, x2, h-y2-1, color[c], aa
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
      line(*p1, *p2, color)
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
    screen.fast_rect x, self.h-y-h, w, h, color[c]
  end

  ##
  # Draw a point at x/y w/ color c.

  def point x, y, c
    screen[x, h-y-1] = color[c]
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
    y = self.h-y-h-1
    screen.draw_rect x, y, w, h, color[c], fill
  end

  ##
  # Draw a circle at x/y with radius r in color c.

  def circle x, y, r, c, fill = false, aa = true
    y = h-y-1
    screen.draw_circle x, y, r, color[c], aa, fill
  end

  ##
  # Draw a circle at x/y with radiuses w/h in color c.

  def ellipse x, y, w, h, c, fill = false, aa = true
    y = self.h-y-1
    screen.draw_ellipse x, y, w, h, color[c], aa, fill
  end

  ##
  # Draw an antialiased curve from x1/y1 to x2/y2 via control points
  # cx1/cy1 & cx2/cy2 in color c.

  def bezier x1, y1, cx1, cy1, cx2, cy2, x2, y2, c, l = 7, aa = true
    h = self.h
    screen.draw_bezier(x1, h-y1-1, cx1, h-cy1, cx2, h-cy2, x2, h-y2-1,
                       l, color[c], aa)
  end

  ## Text

  ##
  # Return the w/h of the text s in font f.

  def text_size s, f = font
    f.text_size s.to_s
  end

  ##
  # Return the rendered text s in color c in font f.

  def render_text s, c, f = font
    f.render screen, s, color[c]
  end

  ##
  # Draw text s at x/y in color c in font f.

  def text s, x, y, c, f = font
    y = self.h-y-f.height-1
    f.draw screen, s, x, y, color[c]
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

  # TODO: copy_rect(x,y,w,h)

  ##
  # Load an image at path into a new surface.

  def image path
    SDL::Surface.load path
  end

  ##
  # Load an audio file at path

  def audio path
    SDL::Audio.load path
  end

  ##
  # Open the audio mixer with a number of +channels+ open.

  def open_mixer channels = 1
    SDL::Audio.open channels
  end

  ##
  # Return the current mouse state: x, y, buttons.

  def mouse
    r = SDL::Mouse.state
    r[1] = h-r[1]
    r
  end

  ##
  # Draw a bitmap centered at x/y with optional angle, x/y scale, and flags.

  def blit src, x, y, a° = 0, xscale = 1, yscale = 1, flags = 0
    bg = color[self.class::CLEAR_COLOR]
    img = src.transform bg, -a°, xscale, yscale, flags

    SDL::Surface.blit img, 0, 0, 0, 0, screen, x-img.w/2, h-y-img.h/2
  end

  ##
  # Draw a bitmap at x/y with optional angle, x/y scale, and flags.

  def put src, x, y, a° = 0, xscale = 1, yscale = 1, flags = 0
    bg = color[self.class::CLEAR_COLOR]
    img = src.transform bg, -a°, xscale, yscale, flags

    # why x-1? because transform adds a pixel to all sides even if a°==0
    SDL::Surface.blit img, 0, 0, 0, 0, screen, x-1, h-y-img.h
  end

  ##
  # Save the current screen to a png.

  def save path
    screen.save path
  end

  ##
  # Create a new sprite with a given width and height and yield to a
  # block with the new sprite as the current screen. All drawing
  # primitives will work and the resulting surface is returned.

  def sprite w, h
    new_screen = SDL::Surface.new w, h, screen.format
    old_screen = screen
    old_w, old_h = self.w, self.h
    self.w, self.h = w, h

    self.screen = new_screen
    yield if block_given?

    new_screen.set_color_key SDL::TRUE, 0

    new_screen
  ensure
    self.screen = old_screen
    self.w, self.h = old_w, old_h
  end
end

##
# A simulation. This ties everything together and provides a bunch of
# convenience methods to make life easier.
#
# In the Model View Controller (MVC) pattern, the simulation is the
# Controller and controls both the window and all bodies involved in
# the simulation. The bodies are the Model and each body class is
# expected to have an inner View class w/ a #draw class method for the
# View.
#
# For example, in examples/bounce.rb:
#
# + BounceSimulation subclasses Graphics::Simulation
# + BounceSimulation has many Balls
# + Ball#update maintains all ball movement.
# + BounceSimulation#draw automatically calls Ball::View.draw on all balls.
# + Ball::View.draw takes a window and a ball and draws it.

class Graphics::Simulation < Graphics::AbstractSimulation
  SCREEN_FLAGS = 0
end

##
# A drawing. Like a Simulation, but on a canvas that doesn't have
# double buffering or clearing on each tick.
#
# See AbstractSimulation for most methods.

class Graphics::Drawing < Graphics::AbstractSimulation
  SCREEN_FLAGS = 0

  def initialize(*a)
    super

    raise "Unknown if this class can continue under SDL2"

    clear
  end

  def draw_and_flip n
    # no flip or draw
  end
end
