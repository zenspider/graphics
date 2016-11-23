module ShowFPS
  def draw n
    super
    fps n
  end
end

module DrawGrid
  def pre_draw n
    super

    (0...w).step(self.class::GRID_WIDTH).each do |x|
      hline x, :gray
      vline x, :gray
    end
  end
end

module WhiteBackground
  CLEAR_COLOR = :white
end
