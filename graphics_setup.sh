#!/bin/sh
set -e

for pkg in sdl sdl_image sdl_ttf sdl_mixer sdl_gfx smpeg freetype libogg libvorbis libsmpeg libpng libtiff; do
    brew uninstall $pkg || true
done

for gem in graphics rubysdl rsdl; do
    gem uninstall -ax $gem || true
done

# brew update

brew install sdl
brew install sdl_mixer --with-smpeg
brew install sdl_ttf
brew install sdl_image

if [ -f $0 ]; then
    rake clean package
    gem install pkg/graphics*.gem
else
    gem install graphics --pre
fi

rsdl -rgraphics -e 'Class.new(Graphics::Simulation) { def draw n; clear :white; text "hit escape to quit", 100, 100, :black; end; }.new(500, 250, 0, "Working!").run'
