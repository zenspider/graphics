##
# Include this in your simulation to automatically include an FPS
# meter.

module ShowFPS
  def draw n # :nodoc:
    super
    fps n
  end
end

##
# Include this in your simulation and define +GRID_WIDTH+ to draw a
# grid in the window.

module DrawGrid
  def pre_draw n # :nodoc:
    super

    (0...w).step(self.class::GRID_WIDTH).each do |x|
      hline x, :gray
      vline x, :gray
    end
  end
end

##
# Include this in your simulation to make the background white.

module WhiteBackground
  CLEAR_COLOR = :white # :nodoc:
  DEBUG_COLOR = :black # :nodoc:
end
