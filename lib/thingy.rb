require "sdl"

class Thingy
  attr_accessor :screen, :w, :h
  attr_accessor :step, :paused
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

    self.paused = self.step = false
  end

  def register_color name, r, g, b
    color[name] = screen.format.map_rgb r, g, b
  end

  def handle_event event, n
    case event
    when SDL::Event::KeyDown then
      key = event.sym.chr rescue event.sym
      case key
      when "q", "Q", "\e" then
        exit
      when " " then
        self.step = true
        self.paused = false
      when "p", "P" then
        self.paused = ! paused
      end
    when SDL::Event::Quit then
      exit
    end
  end

  def run max = nil
    n = 0
    loop do
      self.draw n

      screen.flip

      while event = SDL::Event.poll
        handle_event event, n
      end

      update n unless paused
      n += 1 unless paused

      if step then
        self.paused = true
        self.step = false
      end

      exit if max && n >= max
    end
  end

  def draw n
    raise NotImplementedError, "Subclass Responsibility"
  end

  def update n
    # do nothing
  end

  ## utilities for later
  # .blit(src,srcX,srcY,srcW,srcH,dst,dstX,dstY)
  # put_pixel(x, y, color)
  # []=(x, y, color)
  # get_pixel(x, y)
  # [](x, y)
  # put(src, x, y) # see blit
  # copy_rect(x,y,w,h)
  # transform_surface(bgcolor,angle,xscale,yscale,flags)

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
end
