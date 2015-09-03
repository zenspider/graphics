#!/bin/bash
set -ex

if [[ $OSTYPE == "darwin"* ]]; then

    brew uninstall libpng || true

    brew uninstall sdl || true
    brew uninstall sdl_image || true
    brew uninstall sdl_ttf || true

    brew install libpng

    brew install sdl
    brew install sdl_image
    brew install sdl_ttf

elif [[ "$OSTYPE" == "linux-gnu" ]]; then
    if [[ -f /etc/debian_version ]]; then

        apt-get update -qq && \
            apt-get install -y \
        libsdl-ttf2.0.0 \
        libsdl-sdl-sge \
        libsdl-image1.2-dev \
        libsdl-dev || true

    else
        echo "Unknown version of linux"
        exit 1
    fi
else
    echo "$OSTYPE not supported"
    exit 1
fi

gem uninstall -axI rsdl || true
gem uninstall -axI rubysdl || true

gem install rsdl
gem install rubysdl -- --enable-bundled-sge

ruby -r sdl -e 'p [:sge, SDL.respond_to?(:auto_lock)]'
rsdl -r sdl -e 'SDL.init(SDL::INIT_EVERYTHING); SDL.set_video_mode(640, 480, 16, SDL::SWSURFACE); sleep(1)'
