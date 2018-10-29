require "mkmf"

$VPATH << "$(srcdir)/sge"
$INCFLAGS << " -I$(srcdir)/sge"

$srcs = Dir.glob("#{$srcdir}/{,sge/}*.c{,pp}")

sdl_config = with_config "sdl2-config", "sdl2-config"
$CPPFLAGS   += `#{sdl_config} --cflags`.chomp
if ENV["STRICT"] then # this isn't right because it is at Makefile creation time
  $CPPFLAGS += " "
  $CPPFLAGS += %w[-Werror -Wall
                  -Wimplicit-function-declaration
                  -Wundefined-internal].join(" ")
end
$LOCAL_LIBS += " " + `#{sdl_config} --libs`.chomp

have_library("SDL2_mixer", "Mix_OpenAudio") or abort "Need sdl2_mixer"
have_library("SDL2_image", "IMG_Load")      or abort "Need sdl2_image"
have_library("SDL2_ttf", "TTF_Init")        or abort "Need sdl2_ttf"
have_library("SDL2_gfx", "hlineColor")      or abort "Need sdl2_gfx"

create_makefile "sdl/sdl"
