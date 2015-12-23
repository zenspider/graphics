# -*- coding: utf-8 -*-

require "sdl/sdl"
require "ostruct"
require "graphics/canvas"

module SDL; end # :nodoc: -- stupid rdoc :(

##
# An abstract simulation. See Graphics::Simulation and Graphics::Drawing.

class Graphics::AbstractSimulation

  # degrees to radians
  D2R = Math::PI / 180.0

  # radians to degrees
  R2D = 1 / D2R

  # Call +log+ every N ticks, if +log+ is defined.
  LOG_INTERVAL = 60

  # The window the simulation is drawing in.
  attr_accessor :canvas

  # The environment of the simulation. Keeps track of:
  #   - width and height of canvas
  #   - bodies updated/drawn in engine loop
  #   - any other info needed for updating the simulation
  attr_accessor :env

  # Pause the simulation.
  attr_accessor :paused

  # A hash of color values to their rgb values. For text, apparently. *shrug*
  attr_accessor :rgb

  # Number of update iterations per drawing tick.
  attr_accessor :iter_per_tick

  # Procs registered to handle key events.
  attr_accessor :key_handler

  # Procs registered to handle keydown events.
  attr_accessor :keydown_handler

  ##
  # Create a new simulation of a certain width and height. Optionally,
  # you can set the bits per pixel (0 for current screen settings),
  # the name of the window, and whether or not to run in full screen mode.
  #
  # This also names a bunch colors and hues for convenience.

  def initialize w, h, bpp = 0, name = self.class.name, full = false
    SDL.init SDL::INIT_VIDEO

    full = full ? SDL::FULLSCREEN : 0

    self.canvas = Canvas.new w, h, bpp, name, self.class::SCREEN_FLAGS|full

    self.env = OpenStruct.new :w => w, :h => h, :_bodies => []

    self.paused = false
    self.iter_per_tick = 1

    self.key_handler = []
    self.keydown_handler = {}

    def register_bodies ary
      self.env._bodies << ary
      ary
    end

    initialize_keys
  end

  ##
  # Register default key events. Handles ESC & Q (quit) and P (pause).

  def initialize_keys
    add_keydown_handler("\e") { exit }
    add_keydown_handler("q")  { exit }
    add_keydown_handler("p")  { self.paused = !paused }
    add_keydown_handler("/")  { self.iter_per_tick += 1 }
    add_keydown_handler("-")  { self.iter_per_tick -= 1; self.iter_per_tick = 1  if iter_per_tick < 1 }
  end

  ##
  # Return an array populated by instances of +klass+. You can specify
  # how many to create here or it will access +klass::COUNT+ as the
  # default.

  def populate klass, n = klass::COUNT
    n.times.map {
      o = klass.new self.env
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
    self.env.start_time = Time.now
    n = 0
    event = nil

    logger = respond_to? :log
    log_interval = self.class::LOG_INTERVAL

    loop do
      handle_event event, n while event = SDL::Event.poll
      handle_keys

      next if paused

      iter_per_tick.times { update n; n += 1 }
      draw_and_flip n

      log if logger and n % log_interval == 0
    end
  end

  def draw_and_flip n # :nodoc:
    self.draw n
    canvas.screen.flip
  end

  ##
  # Draw the scene by clearing the window and drawing all registered
  # bodies. You are free to completely override this or call super and
  # add any extras at the end.

  def draw n
    clear

    self.env._bodies.each do |ary|
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
      cls.draw canvas, obj
    end
  end

  ##
  # Update the simulation by telling all registered bodies to update.
  # You are free to completely override this or call super and add any
  # extras at the end.

  def update n
    self.env.n = n
    self.env._bodies.each do |ary|
      ary.each(&:update)
    end
  end

  ##
  # Clear the whole screen

  def clear c = :black
    canvas.fast_rect 0, 0, env.w, env.h, c
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
#  BounceSimulation subclasses Graphics::Simulation
#  BounceSimulation has many Balls
#  Ball#update maintains all ball movement.
#  BounceSimulation#draw automatically calls Ball::View.draw on all balls.
#  Ball::View.draw takes a window and a ball and draws it.

class Graphics::Simulation < Graphics::AbstractSimulation
    SCREEN_FLAGS = SDL::HWSURFACE|SDL::DOUBLEBUF
end

##
# A drawing. Like a Simulation, but on a canvas that doesn't have
# double buffering or clearing on each tick.
#
# See AbstractSimulation for most methods.

class Graphics::Drawing < Graphics::AbstractSimulation
  SCREEN_FLAGS = SDL::HWSURFACE

  def initialize(*a)
    super

    clear
  end

  def draw_and_flip n
    screen.update 0, 0, 0, 0
    # no flip
  end
end

if $0 == __FILE__ then
  SDL.init SDL::INIT_EVERYTHING
  SDL.set_video_mode(640, 480, 16, SDL::SWSURFACE)
  sleep 1
  puts "if you saw a window, it was working"
end
