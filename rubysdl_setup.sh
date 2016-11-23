#!/bin/sh
set -ex

brew uninstall libogg || true
brew uninstall libvorbis || true
brew uninstall libpng || true

brew uninstall sdl || true
brew uninstall sdl_ttf || true
brew uninstall sdl_mixer || true
brew uninstall sdl_image || true

gem uninstall -ax rsdl || true
gem uninstall -ax rubysdl || true
gem uninstall -ax graphics || true

# brew update

brew install sdl
brew install sdl_mixer --with-smpeg
brew install sdl_ttf
brew install sdl_image

# gem install graphics --pre
