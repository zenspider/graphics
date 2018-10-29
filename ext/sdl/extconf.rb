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
# have_library("SDL2_gfx", "fuck")          or abort "Need sdl2_gfx"

# have_func "TTF_OpenFontIndex"
# have_func "TTF_FontFaces"
# have_func "TTF_FontFaceIsFixedWidth"
# have_func "TTF_FontFaceFamilyName"
# have_func "TTF_FontFaceStyleName"
# have_func "Mix_LoadMUS_RW"
# have_func "rb_thread_blocking_region"
# have_func "rb_thread_call_without_gvl" if have_header "ruby/thread.h"

# if have_func("rb_enc_str_new") && have_func("rb_str_export_to_enc")
#   $CPPFLAGS += " -D ENABLE_M17N"
#   $CPPFLAGS += " -D ENABLE_M17N_FILESYSTEM" if enable_config "m17n-filesystem", false
# end

create_makefile "sdl/sdl"
