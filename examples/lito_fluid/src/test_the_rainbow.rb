require './lib/thingy'

WINSIZE = 500

class SimulationWindow < Thingy
  attr_reader :simulation
  def initialize
    super WINSIZE, WINSIZE, 16, "Smoothed Particle Hydrodynamics"
  end

  def draw time
    blank
    #text time.to_s, 50, 50, :white
    r, g, b = spectrum(time)
    text r.to_s, 50, 10, :white
    text g.to_s, 50, 50, :white
    text b.to_s, 50, 100, :white
    fill_rect(
      200,
      200,
      150,
      150,
      self.spectrum(time)
    )
  end
end

SimulationWindow.new.run
