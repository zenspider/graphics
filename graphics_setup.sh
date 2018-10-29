#!/bin/sh
set -e
set -v

# if [ $(id -u) != 0 ]; then
#     echo "Please run this as root or with sudo"
#     exit 1
# fi

for gem in graphics rsdl; do
  gem uninstall -ax $gem || true
done

case `uname` in
    Darwin)
	echo "I'm on OSX. Not using sudo"
	SUDO=

	brew unlink sdl
	brew unlink sdl_mixer
	brew unlink sdl_ttf
	brew unlink sdl_image

	brew install sdl2
	brew install sdl2_mixer
	brew install sdl2_ttf
	brew install sdl2_image --without-webp
	;;
    Linux)
	echo "I'm on linux, using sudo where needed"
	SUDO=sudo

	$SUDO apt-get install --no-install-recommends --no-install-suggests libsdl1.2-dev libsdl-image1.2-dev libsdl-mixer1.2-dev libsdl-ttf2.0-dev
	$SUDO apt-get install --no-install-recommends --no-install-suggests gcc g++
	;;
    *)
	echo "Unknown OS $OSTYPE, aborting"
	exit 1
	;;
esac

$SUDO gem update --system -N -V

gem install hoe --conservative
$SUDO rake newb
rake test

if [ -f $0 ]; then
    rake clean package
    $SUDO gem install pkg/graphics*.gem
else
    $SUDO gem install graphics --pre
fi

rsdl -Ilib -rgraphics -e 'Class.new(Graphics::Simulation) { def draw n; clear :white; text "hit escape to quit", 100, 100, :black; end; }.new(500, 250, 0, "Working!").run'
