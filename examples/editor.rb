#!/usr/local/bin/ruby -w
# -*- coding: utf-8 -*-

require "graphics"

class Editor < Graphics::Simulation
  attr_accessor :overlay, :s, :lines

  alias :overlay? :overlay

  def initialize
    super 850, 850

    self.overlay = true
    self.s = ""
    self.lines = []
  end

  def initialize_keys
    # no super
    add_key_handler(:ESCAPE) { exit }
  end

  def handle_event e, n
    case e
    when SDL::Event::Keydown then
      if e.mod & (SDL::Key::MOD_LCTRL | SDL::Key::MOD_RCTRL) != 0 then
        case e.sym.chr
        when "t" then
          self.overlay = ! self.overlay
        end
      else
        c = e.sym.chr rescue ""
        c.upcase! if e.mod & (SDL::Key::MOD_LSHIFT | SDL::Key::MOD_RSHIFT) != 0
        case c
        when "\r" then
          c = "\n"
          lines << s.dup
          s.clear
          return
        when "\b" then
          self.s = s[0..-2]
          return
        end
        s << c
      end
    else
      super
    end
  end

  def draw n
    clear

    draw_scene
    draw_overlay
  end

  def draw_scene
  end

  def draw_overlay
    return unless overlay?

    lines.each_with_index do |l, i|
      text l, 10, ((lines.size-i)*font.height), :gray
    end

    text "> #{s}_", 10, 0, :white
  end
end

Editor.new.run if $0 == __FILE__
