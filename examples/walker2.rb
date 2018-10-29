#!/usr/local/bin/ruby -w

require "graphics"
require "graphics/trail"

class Person < Graphics::Body
  COUNT = 40

  D_A = 5.0
  D_M = 0.25
  M_M = 5.0

  VISIBILITY         = 100
  ATTACK_DISTANCE    = 6 * 2
  VISIBILITY_SQ      = VISIBILITY**2
  ATTACK_DISTANCE_SQ = ATTACK_DISTANCE**2

  attr_accessor :attack, :debug
  alias attack? attack
  alias debug? debug

  def initialize w
    super

    self.a  = random_angle
    self.ga = random_angle
    self.attack = false
    self.debug = false
  end

  def update
    return update_attack if attack?

    normal_update
  end

  def normal_update
    turn_towards_goal
    possibly_change_goal

    # accelerate
    # move

    wrap
  end

  def near? p
    distance_to_squared(p) < VISIBILITY_SQ
  end

  def visible? o
    pa = self.angle_to o
    da = (pa - self.a + 90).degrees
    da.between?(75, 150)
  end

  def nearby
    @nearby ||= begin
                  all_but_me = w.ps.reject(&:attack?)
                  nearby     = all_but_me.find_all { |p| self.near? p }
                  visible    = nearby.select { |p| self.visible? p }
                  visible.sort_by { |p| self.distance_to_squared(p) }
                end
  end

  def update_attack
    @nearby = nil

    nearby.each do |p|
      dist = self.distance_to_squared(p)

      if dist <= ATTACK_DISTANCE_SQ then
        p.kill
      else
        self.ga = self.angle_to(nearby.first)
      end
    end

    normal_update
  end

  def kill
    w.ps.delete self unless attack?
  end

  def accelerate
    max = attack ? 1.1 * M_M : M_M
    self.m += D_M unless m >= max
  end

  def turn_towards_goal
    turn a.relative_angle(ga, D_A)
  end

  def change_goal
    self.ga = (a + random_turn(180)).degrees
  end

  def possibly_change_goal
    close = ga.close_to?(a)
    change = close && 1 =~ 25
    change_goal if change
  end

  def collide_with? other
    w.cmap.check(x, y, w.cmap, other.x, other.y) != nil
  end

  def collide b
    return b.kill if self.attack?
    self.a = (a + 180).degrees
    change_goal
  end

  class View
    def self.draw w, b
      x, y, a, ga = b.x, b.y, b.a, b.ga

      if b.debug? and b.attack? then
        w.angle x, y, a-75, VISIBILITY, :yellow
        w.angle x, y, a-25, VISIBILITY, :yellow
        w.angle x, y, a+25, VISIBILITY, :yellow
        w.angle x, y, a+75, VISIBILITY, :yellow
        b.nearby.each do |o|
          w.line x, y, o.x, o.y, :yellow
        end
        # sleep 0.25 unless nearby.empty?
      end

      w.angle x, y,  a,   20, :green
      w.angle x, y, ga,   10, :red

      # the blit looks HORRIBLE when rotated... dunno why
      w.blit w.body_img, x, y
      w.circle x, y, 5, :red, :filled if b.attack?
    end
  end
end

class WalkerSimulation < Graphics::Simulation
  attr_accessor :ps, :body_img, :cmap

  def initialize
    super 850, 850

    self.ps = populate Person, 2
    register_bodies ps

    # 5.times do |n|
    #   ps[n].attack = true
    # end

    ps[0].debug = true
    ps[0].attack = true

    ps.first.x = w/2
    ps.first.y = h/2
    ps.first.a = 90
    ps.first.ga = 90

    ps.last.x = w/2 + 50
    ps.last.y = h/2 + 50
    ps.last.a = 0
    ps.last.ga = 0

    self.body_img = sprite 20, 20 do
      circle 10, 10, 5, :white, :filled
    end

    self.cmap = body_img.make_collision_map
  end

  def update n
    super

    detect_collisions(ps).each do |a, b|
      a.collide b
    end

    exit if ps.all?(&:attack?)
  end

  def draw n
    super

    debug "#{ps.size}"
    fps n
  end

  def detect_collisions sprites
    collisions = []
    sprites.combination(2).each do |a, b|
      collisions << [a, b] if a.collide_with? b
    end
    collisions
  end
end

WalkerSimulation.new.run
