require "graphics"

class Tree < Graphics::Simulation
  def initialize max_height: 9, branch_length: 11, max_angle_change: 20, branch_color: nil, screen_width: 800, screen_height: 800
    super screen_width, screen_height

    @tree_height = 0
    @angle_change = 0
    @branch_length = branch_length
    @branch_color = branch_color
    @max_angle_change = max_angle_change
    @max_tree_height = max_height
  end

  def draw n
    # Go slowly
    return unless n % 35 == 0

    super

    # 0 is bottom of screen
    # 90 degrees is straight up
    tree (w / 2), 0, 90, @tree_height, @branch_length, @angle_change, get_color

    # Grow tree slowly
    if @tree_height <= @max_tree_height
      @tree_height += 1
    end

    if @angle_change <= @max_angle_change
      @angle_change += 1
    end
  end

  # Draw the tree recursively
  def tree x1, y1, angle, depth, branch_length, angle_change, color
    return if depth == 0

    x2 = x1 + (Math.cos(D2R * angle) * depth * branch_length).to_i
    y2 = y1 + (Math.sin(D2R * angle) * depth * branch_length).to_i

    line x1, y1, x2, y2, color

    tree x2, y2, angle - angle_change, depth - 1, branch_length, angle_change, get_color
    tree x2, y2, angle + angle_change, depth - 1, branch_length, angle_change, get_color
  end

  # Either use supplied color or use a random color
  def get_color
    if @branch_color
      @branch_color
    else
      @colors ||= color.keys.sort
      @colors.sample
    end
  end
end

Tree.new(branch_color: :green).run if $0 == __FILE__
