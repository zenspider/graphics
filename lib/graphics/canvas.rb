class Canvas
  attr_accessor :screen, :w, :h, :color, :rgb, :font

  # degrees to radians
  D2R = Math::PI / 180.0

  # radians to degrees
  R2D = 1 / D2R


  def initialize w, h, bpp, name, full
    self.w = w
    self.h = h

    SDL::WM.set_caption name, name

    self.color = {}
    self.rgb   = Hash.new { |hash, k| hash[k] = canvas.format.get_rgb(color[k]) }

    self.font = find_font("Menlo", 32)

    self.screen = SDL::Screen.open w, h, bpp, SDL::HWSURFACE|SDL::DOUBLEBUF|full

    initialize_colors
  end

  sys_font  = "/System/Library/Fonts"
  lib_font  = "/Library/Fonts"
  user_font = File.expand_path "~/Library/Fonts/"
  FONT_GLOB = "{#{sys_font},#{lib_font},#{user_font}}" # :nodoc:

  ##
  # Find and open a (TTF) font. Should be as system agnostic as possible.

  def find_font name, size = 16
    font = Dir["#{FONT_GLOB}/#{name}.{ttc,ttf}"].first

    raise ArgumentError, "Can't find font named '#{name}'" unless font

    SDL::TTF.open(font, size)
  end


  def initialize_colors # :nodoc:
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
    if fill then
      screen.fill_rect x, y, w, h, color[c]
    else
      screen.draw_rect x, y, w, h, color[c]
    end
  end

  ##
  # Draw a circle at x/y with radius r in color c.

  def circle x, y, r, c, fill = false
    y = self.h-y-1
    if fill then
      screen.fill_circle x, y, r, color[c]
    else
      screen.draw_circle x, y, r, color[c]
    end
  end

  ##
  # Draw a circle at x/y with radiuses w/h in color c.

  def ellipse x, y, w, h, c, fill = false
    y = self.h-y-1
    if fill then
      screen.fill_ellipse x, y, w, h, color[c]
    else
      screen.draw_ellipse x, y, w, h, color[c]
    end
  end

  ##
  # Draw an antialiased curve from x1/y1 to x2/y2 via control points
  # cx1/cy1 & cx2/cy2 in color c.

  def bezier x1, y1, cx1, cy1, cx2, cy2, x2, y2, c, l = 7
    h = self.h
    screen.draw_bezier x1, h-y1-1, cx1, h-cy1, cx2, h-cy2, x2, h-y2-1, l, color[c]
  end

  ##
  # Draw an antialiased line from x1/y1 to x2/y2 in color c.

  def line x1, y1, x2, y2, c
    h = self.h
    screen.draw_line x1, h-y1-1, x2, h-y2-1, color[c]
  end

  ##
  # Draw a horizontal line from x1 to x2 at y in color c.

  def hline y, c, x1 = 0, x2 = self.h
    line x1, y, x2, y, c
  end

  ##
  # Draw a vertical line from y1 to y2 at y in color c.

  def vline x, c, y1 = 0, y2 = self.w
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

  ## Text

  ##
  # Return the w/h of the text s in font f.

  def text_size s, f = font
    f.text_size s
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
  # Create a new sprite with a given width and height and yield to a
  # block with the new sprite as the current screen. All drawing
  # primitives will work and the resulting surface is returned.

  def sprite w2, h2
    new_screen = SDL::Surface.new w2, h2, screen.format
    old_screen = self.screen
    old_w, old_h = self.w, self.h
    self.w, self.h = w2, h2

    self.screen = new_screen
    yield if block_given?

    new_screen.set_color_key SDL::SRCCOLORKEY, 0

    new_screen
  ensure
    self.screen = old_screen
    self.w, self.h = old_w, old_h
  end

  ##
  # Draw a bitmap centered at x/y with optional angle, x/y scale, and flags.

  def blit src, x, y, a° = 0, xscale = 1, yscale = 1, flags = 0
    img = src.transform src.format.colorkey, -a°, xscale, yscale, flags

    SDL::Surface.blit img, 0, 0, 0, 0, screen, x-img.w/2, self.h-y-img.h/2
  end

  ##
  # Draw a bitmap at x/y with optional angle, x/y scale, and flags.

  def put src, x, y, a° = 0, xscale = 1, yscale = 1, flags = 0
    img = src.transform src.format.colorkey, -a°, xscale, yscale, flags

    # why x-1? because transform adds a pixel to all sides even if a°==0
    SDL::Surface.blit img, 0, 0, 0, 0, screen, x-1, self.h-y-img.h
  end

  ##
  # Return the current mouse state: x, y, buttons.
  # TODO: Should be in the interactive part, not canvas

  def mouse
    r = SDL::Mouse.state
    r[1] = h-r[1]
    r
  end

  ##
  # Draw the current frames-per-second in the top left corner in green.

  def fps n, start_time
    secs = Time.now - start_time
    fps = "%5.1f fps" % [n / secs]
    self.text fps, 10, self.h-font.height, :green
  end

  ##
  # Print out some extra debugging information underneath the fps line
  # (if any).

  def debug fmt, *args
    s = fmt % args
    text s, 10, self.h-40-font.height, :white
  end









end
