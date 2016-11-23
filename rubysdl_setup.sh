#!/bin/sh
set -ex

brew uninstall libogg || true
brew uninstall libvorbis || true
brew uninstall libpng || true

brew uninstall sdl || true
brew uninstall sdl_ttf || true
brew uninstall sdl_mixer || true
brew uninstall sdl_image || true

# brew update

brew install libogg
brew install libvorbis
brew install libpng

brew install sdl
brew install sdl_mixer
brew install sdl_ttf
brew install sdl_image

gem uninstall -ax rsdl || true
gem install rsdl

ruby -r sdl -e 'p [:ttf, SDL.constants.include?(:TTF)]'
ruby -r sdl -e 'p [:mixer, SDL.constants.include?(:Mixer)]'
ruby -r sdl -e 'p [:sge, SDL.respond_to?(:auto_lock)]'

rsdl -r sdl -e 'SDL.init(SDL::INIT_EVERYTHING); SDL.set_video_mode(640, 480, 16, SDL::SWSURFACE); sleep(1)'
