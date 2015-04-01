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

  ### drawing routines:

  def clear c = :black
    fill_rect 0, 0, w, h, c
  end

  def line x1, y1, x2, y2, c
    screen.draw_line x1, y1, x2, y2, color[c]
  end

  def text s, x, y, c, f = font
    f.draw_solid_utf8(screen, s, x, y, *rgb[c])
  end

  def ellipse x, y, w, h, c
    screen.draw_ellipse x, y, w, h, color[c]
  end

  def fill_rect x, y, w, h, c
    screen.fill_rect x, y, w, h, color[c]
  end
end
