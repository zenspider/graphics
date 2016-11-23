#!/usr/local/bin/ruby -w

srand 42

require "thingy"

class Entity
  attr_accessor :x, :y
  attr_accessor :speed
  attr_accessor :sim

  @@colors = false

  def initialize sim
    self.sim = sim
    self.speed = 5

    self.x = rand(sim.w / sim.scale)
    self.y = rand(sim.h / sim.scale)
  end

  def distance_from_squared p
    dx = p.x - x
    dy = p.y - y
    dx * dx + dy * dy
  end

  VISIBILITY = 16
  VIS_SQ = VISIBILITY * VISIBILITY

  def near? p
    distance_from_squared(p) < VIS_SQ
  end

  def touching? p
    distance_from_squared(p) < 4 # 2 * 2
  end

  def partition
    (x / sim.width_of_partition) + sim.side * (y / sim.width_of_partition)
  end

  def random_walk
    self.x += rand(speed)-speed/2
    self.y += rand(speed)-speed/2
  end

  def max
    @@max ||= sim.max
  end

  def limit_bounds
    self.x = 0       if x < 0
    self.x = max - 1 if x >= max
    self.y = 0       if y < 0
    self.y = max - 1 if y >= max
    # self.x = [[0, @x].max, sim.max - 1].min
    # self.y = [[0, @y].max, sim.max - 1].min
  end

  def move_towards entity
    self.x += (entity.x - x) <=> 0
    self.y += (entity.y - y) <=> 0
    limit_bounds
  end

  # def move_away_from entity
  #   @x += (x - entity.x) <=> 0 # 2 - 1 = 1
  #   @y += (y - entity.y) <=> 0 # 2 - 1 = 1
  #   limit_bounds
  # end

  def draw
    raise "subclass responsibility"
  end
end

class Person < Entity
  COUNT = 750

  NORMAL = 1
  FREAKD = 2
  INFECT = 3

  INFECT_STEPS = 50.0 # must be a float

  NORMAL_COLOR = :blue
  FREAKD_COLOR = :yellow

  attr_accessor :state, :infect, :speed

  def initialize sim, state = NORMAL
    super(sim)

    self.state = state
    self.speed = 5
    self.infect = nil

    initialize_colors unless @@colors
  end

  def initialize_colors
    @@colors = true

    INFECT_STEPS.to_i.times do |n|
      r = (255 * ((INFECT_STEPS - n) / INFECT_STEPS)).to_i
      g = (192 * (n / INFECT_STEPS)).to_i
      b = 0
      sim.register_color "infect#{n}", r, g, b
    end
  end

  def infected?
    state == INFECT
  end

  def freaked?
    state == FREAKD
  end

  def color
    case state
    when NORMAL
      NORMAL_COLOR
    when FREAKD
      FREAKD_COLOR
    when INFECT
      "infect#{INFECT_STEPS.to_i - infect}"
    end
  end

  def draw
    sim.fast_rect x*2, y*2, 2, 2, color
  end

  def update_infection
    if @infect then
      @infect -= 1
      sim.zombie << Zombie.from_person(sim.person.delete(self), sim) if @infect <= 0
      true
    end
  end

  def visible
    sim.part_z[partition].find_all { |p| self.near? p }
  end

  def nearest
    visible.sort_by { |p| self.distance_from_squared p }.first
  end

  def update i
    return if update_infection
    random_walk
    limit_bounds

    nearest = self.nearest
    # nearby_zombies = sim.part_z[partition].find_all { |p| self.near? p }

    unless nearest then # nearby_zombies.empty? then # no zombies nearby
      if state == FREAKD then
        self.state = NORMAL
        self.speed = 5
      end
    else
      unless touching? nearest then # nearby_zombies.find_all { |z| touching? z }.empty? then
        if state == NORMAL then
          self.state = FREAKD
          self.speed = 9
        end
      else
        self.state  = INFECT
        self.infect = INFECT_STEPS.to_i
      end
    end
  end

  def kill
    sim.person.delete self
  end
end

class Hunter < Person
  COUNT = 6
  COLOR = :white

  def color
    if @infect then
      "infect#{INFECT_STEPS.to_i - infect}"
    else
      COLOR
    end
  end

  def update i
    return if update_infection
    random_walk
    limit_bounds

    baddies = sim.zombie + sim.person.select(&:infect) # sim.part_z[partition] + sim.part_p[partition].select { |p| p.infect }
    nearest = baddies.sort_by { |z| self.distance_from_squared z }.first
    if nearest then
      if self.touching? nearest then
        if Person === nearest then
          nearest.kill
        else
          if rand(10) != 0 then
            nearest.kill
          else
            self.state = INFECT
            self.infect = INFECT_STEPS.to_i
          end
        end
      elsif near? nearest then
        move_towards nearest
      else
        move_towards nearest
        # nearest_p, nearest_z = baddies.partition { |o| Person === o }.map(&:first)
        # move_towards nearest_z || nearest_p
      end
    end
  end

  def draw
    sim.circle x*2, y*2, VISIBILITY, color
    super
  end
end

class Zombie < Entity
  COUNT = 5
  ZOMBIE_COLOR = :red

  def self.from_person p, sim
    z = new sim
    z.x = p.x
    z.y = p.y
    z
  end

  def initialize sim
    super
    self.speed = 3
  end

  def draw
    sim.fast_rect x*2, y*2, 2, 2, ZOMBIE_COLOR
  end

  def visible
    sim.part_p[partition].find_all { |p| Hunter === p || p.freaked? }
  end

  def nearest
    visible.sort_by { |p| self.distance_from_squared p }.first
  end

  def update i
    nearest = self.nearest

    if nearest then
      move_towards nearest
    else
      random_walk
    end

    limit_bounds
  end

  def kill
    sim.zombie.delete self
  end
end

class ZombieGame < Thingy
  attr_accessor :person, :zombie
  attr_accessor :part_p, :part_z
  attr_accessor :scale, :partitions
  attr_accessor :start

  def initialize
    super 512, 512, 16, "Zombie Epidemic Simulator"
    self.scale = 2
    self.partitions = 64

    self.part_p = Array.new(partitions) do [] end
    self.part_z = Array.new(partitions) do [] end

    self.person = []
    self.zombie = []

    populate Person, person
    populate Zombie, zombie
    populate Hunter, person

    self.start = Time.now
  end

  def draw tick
    clear

    person.each do |p|
      p.draw
    end

    zombie.each do |p|
      p.draw
    end

    fps tick
  end

  def update i
    partition_into person, part_p, partitions, side
    partition_into zombie, part_z, partitions, side

    person.each do |p|
      p.update i
    end

    zombie.each do |p|
      p.update i
    end

    if zombie.empty? or person.all?(&:infected?) then
      t = Time.now - start
      if zombie.empty? then
        print "Infestation stopped "
      else
        print "All people infected "
      end
      puts "in #{i} iterations, #{t} sec"
      puts "  #{i / t} frames / sec"

      exit
    end
  end

  def populate klass, coll
    klass::COUNT.times do
      coll << klass.new(self)
    end
  end

  # TODO: rename
  def side
    @side ||= Math.sqrt(partitions).to_i
  end

  def partition_into from, to, size, side
    to.each(&:clear)

    from.each do |p|
      part = p.partition

      # -3 or less - do nothing
      # -2         - add 0
      # -1         - add 0, 1
      # 0 or more  - add idx..idx+2

      idx = part - side - 1
      if idx >= 0 then
        to[idx]   << p
        to[idx+1] << p
        to[idx+2] << p
      else
        to[0] << p if idx >= -2
        to[1] << p if idx >= -1
      end

      #       case idx
      #       when -2 then
      #         to[0] << p
      #       when -1 then
      #         to[0] << p
      #         to[1] << p
      #       else
      #         to[idx]   << p
      #         to[idx+1] << p
      #         to[idx+2] << p
      #       end

      ############################################################

      #       idx = part - side - 1
      #       to[idx] << p if idx >= 0
      #       idx += 1
      #       to[idx] << p if idx >= 0
      #       idx += 1
      #       to[idx] << p if idx >= 0

      idx = part - 1
      to[idx] << p if idx >= 0
      idx += 1
      to[idx] << p
      idx += 1
      to[idx] << p if idx < size

      idx = part + side - 1
      to[idx] << p if idx < size
      idx += 1
      to[idx] << p if idx < size
      idx += 1
      to[idx] << p if idx < size
    end
  end

  def width_of_partition
    @width_of_partition ||= (w / scale) / side
  end

  def max
    @max ||= w / scale
  end
end

ZombieGame.new.run
