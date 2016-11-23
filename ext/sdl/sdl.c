#include <SDL.h>
#include <ruby.h>
#include <ruby/intern.h>
#include <SDL_ttf.h>
#include <SDL_image.h>
#include <sge.h>
#include <SDL_mixer.h>

// https://github.com/google/protobuf/blob/master/ruby/ext/google/protobuf_c/defs.c

#define DEFINE_CLASS_(name, string_name, mark, free, memsize)    \
  static void mark(void*);                                       \
  static void free(void*);                                       \
  static VALUE c##name;                                          \
  static const rb_data_type_t _##name##_type = {                 \
    string_name,                                                 \
    { mark, free, memsize, { NULL, NULL }, }, NULL, NULL,        \
  };                                                             \
  static SDL_##name* ruby_to_##name(VALUE val) {                 \
    SDL_##name* ret;                                             \
    TypedData_Get_Struct(val, SDL_##name, &_##name##_type, ret); \
    return ret;                                                  \
  }

#define DEFINE_CLASS(name, string_name)                          \
  static size_t _##name##_memsize(const void *);                 \
  DEFINE_CLASS_(name, string_name,                               \
                  _##name##_mark, _##name##_free, _##name##_memsize)

#define DEFINE_CLASS_0(name, string_name)                        \
  DEFINE_CLASS_(name, string_name, _##name##_mark, _##name##_free, NULL)

#define DEFINE_SELF(type, var, rb_var)                           \
  SDL_##type* var = ruby_to_##type(rb_var)

#define NUM2SINT32(n) (Sint32)NUM2INT(n)
#define NUM2SINT16(n) (Sint16)NUM2INT(n)
#define NUM2UINT32(n) (Uint32)NUM2UINT(n)
#define NUM2UINT16(n) (Uint16)NUM2UINT(n)
#define NUM2UINT8(n)  (Uint8)NUM2INT(n)
#define INT2BOOL(n)   ((n)?Qtrue:Qfalse)
#define NUM2FLT(n)    (float)NUM2DBL(n)

#define NewRect(x,y,w,h) { NUM2SINT16(x), NUM2SINT16(y), NUM2UINT16(w), NUM2UINT16(h) }

#define UNUSED(x) (void)(x)

#define ZERO_RECT(r) r.x == 0 && r.y == 0 && r.w == 0 && r.h == 0

#define FAILURE(s) rb_raise(eSDLError, "%s failed: %s", (s), SDL_GetError());
#define AUDIO_FAILURE(s) rb_raise(eSDLError, "%s failed: %s", (s), Mix_GetError());

#ifdef rb_intern
#undef rb_intern // HACK -- clang warns about recursive macros
#endif

#define DEFINE_ID(name) static ID id_iv_##name
#define INIT_ID(name) id_iv_##name = rb_intern("@"#name)

#define DEFINE_DRAW6(type, name, func) \
  static VALUE Surface_##name(VALUE s, VALUE x, VALUE y, VALUE w, VALUE h, VALUE c) { \
    return _draw_func_##type(&func, s, x, y, w, h, c); \
  }

#define DEFINE_SXYRC(name, func) \
  static VALUE Surface_##name(VALUE s, VALUE x, VALUE y, VALUE r, VALUE c) { \
    return _draw_func_sxyrc(&func, s, x, y, r, c); \
  }

#define DEFINE_SXYXYC(name, func) DEFINE_DRAW6(sxyxyc, name, func)
#define DEFINE_SXYWHC(name, func) DEFINE_DRAW6(sxywhc, name, func)

static VALUE cEvent;
static VALUE cEventKeydown;
static VALUE cEventKeyup;
static VALUE cEventMousedown;
static VALUE cEventMousemove;
static VALUE cEventMouseup;
static VALUE cEventQuit;
static VALUE cScreen;
static VALUE eSDLError;
static VALUE eSDLMem;
static VALUE mKey;
static VALUE mSDL;
static VALUE mWM;
static VALUE mMouse;

typedef TTF_Font SDL_TTFFont;
typedef Mix_Chunk SDL_Audio;
typedef sge_cdata SDL_CollisionMap;

DEFINE_ID(button);
DEFINE_ID(mod);
DEFINE_ID(press);
DEFINE_ID(state);
DEFINE_ID(sym);
DEFINE_ID(unicode);
DEFINE_ID(x);
DEFINE_ID(xrel);
DEFINE_ID(y);
DEFINE_ID(yrel);

DEFINE_CLASS(Audio,        "SDL::Audio")
DEFINE_CLASS(Surface,      "SDL::Surface")
DEFINE_CLASS(CollisionMap, "SDL::CollisionMap")
DEFINE_CLASS(PixelFormat,  "SDL::PixelFormat")
DEFINE_CLASS_0(TTFFont,    "SDL::TTFFont")

typedef VALUE (*event_creator)(SDL_Event *);
static event_creator event_creators[SDL_NUMEVENTS];

static int is_quit = 0;
static Uint8* key_state = NULL;
static SDLMod mod_state;

void Init_sdl(void);

//// Misc / Utility functions:

// TODO: collapse to one format
static Uint32 VALUE2COLOR(VALUE color, SDL_PixelFormat *format) {
  // TODO: reverse and use FIXNUM_P ?
  if (rb_obj_is_kind_of(color, rb_cArray)) {
    switch (RARRAY_LEN(color)) {
    case 3:
      return SDL_MapRGB(format,
                        (Uint8)FIX2UINT(rb_ary_entry(color, 0)),
                        (Uint8)FIX2UINT(rb_ary_entry(color, 1)),
                        (Uint8)FIX2UINT(rb_ary_entry(color, 2)));
    case 4:
      return SDL_MapRGBA(format,
                         (Uint8)FIX2UINT(rb_ary_entry(color, 0)),
                         (Uint8)FIX2UINT(rb_ary_entry(color, 1)),
                         (Uint8)FIX2UINT(rb_ary_entry(color, 2)),
                         (Uint8)FIX2UINT(rb_ary_entry(color, 3)));
    default:
      rb_raise(rb_eArgError, "type mismatch:color array needs 3 or 4 elements");
    }
  } else {
    return NUM2UINT(color);
  }
}

//// SDL methods:

static VALUE sdl_s_init(VALUE mod, VALUE flags) {
  UNUSED(mod);
  if (SDL_Init(NUM2UINT(flags)))
    FAILURE("SDL.init");

  if (TTF_Init())
    rb_raise(eSDLError, "TTF_Init error: %s", TTF_GetError());

  return Qnil;
}

static void sdl__quit(VALUE v) {
  UNUSED(v);
  if (is_quit) return;
  is_quit = 1;

  TTF_Quit();
  SDL_Quit();
}

//// SDL::Audio methods:

static void _Audio_free(void* p) {
  // if (is_quit) return;
  if (!p) return;

  Mix_Chunk *chunk = p;

  if (Mix_QuerySpec(NULL, NULL, NULL))
    Mix_FreeChunk(chunk);
}

static void _Audio_mark(void* p) {
  UNUSED(p);
}

static size_t _Audio_memsize(const void *p) {
  return p ? sizeof(Mix_Chunk) + ((Mix_Chunk*)p)->alen : 0;
}

static VALUE Audio_s_open(VALUE self, VALUE n_channels) {
  UNUSED(self);
  int n = NUM2INT(n_channels);

  // TODO: int Mix_Init(MIX_INIT_MP3) ?

  if (Mix_QuerySpec(NULL, NULL, NULL))
    return Qnil; // TODO: raise?

  if (Mix_OpenAudio(22050, MIX_DEFAULT_FORMAT, 2, 4096))
    AUDIO_FAILURE("SDL::Audio.open");

  return INT2FIX(Mix_AllocateChannels(n));
}

static VALUE Audio_s_load(VALUE self, VALUE path) {
  UNUSED(self);
  ExportStringValue(path);

  Mix_Chunk *chunk = Mix_LoadWAV(RSTRING_PTR(path));

  if (!chunk)
    FAILURE("Audio.load");

  return TypedData_Wrap_Struct(cAudio, &_Audio_type, chunk);
}

static VALUE Audio_play(VALUE self) {
  DEFINE_SELF(Audio, audio, self);

  if (Mix_PlayChannel(-1, audio, 0) < 0)
    AUDIO_FAILURE("Audio#play");

  return Qnil;
}

//// SDL::CollisionMap methods:

static void _CollisionMap_free(void* p) {
  if (is_quit) return;
  if (!p) return;

  SDL_PixelFormat *format = p;

  if (format->palette) {
    free(format->palette->colors);
    free(format->palette);
  }

  free(format);
}

static void _CollisionMap_mark(void* p) {
  UNUSED(p);
}

static size_t _CollisionMap_memsize(const void *p) {
  return p ? sizeof(sge_cdata) : 0;
}

static VALUE CollisionMap_check(VALUE cmap1, VALUE x1, VALUE y1,
                                VALUE cmap2, VALUE x2, VALUE y2) {
  DEFINE_SELF(CollisionMap, cdata1, cmap1);
  DEFINE_SELF(CollisionMap, cdata2, cmap2);

  if(!sge_cmcheck(cdata1, NUM2SINT16(x1), NUM2SINT16(y1),
                  cdata2, NUM2SINT16(x2), NUM2SINT16(y2)))
    return Qnil;

  return rb_ary_new3(2, INT2NUM(sge_get_cx()), INT2NUM(sge_get_cy()));
}

//// SDL::Event methods:

static VALUE Event_s_poll(VALUE self) {
  UNUSED(self);
  SDL_Event event;

  return SDL_PollEvent(&event) == 1 ? event_creators[event.type](&event) : Qnil;
}

static VALUE Event__null(SDL_Event *event) {
  UNUSED(event);
  return Qnil;
}

static VALUE Event__quit(SDL_Event *event) {
  UNUSED(event);
  return rb_obj_alloc(cEventQuit);
}

static VALUE __new_key_event(VALUE klass, SDL_Event *event) {
  VALUE obj = rb_obj_alloc(klass); // TODO: TypedData_Wrap_Struct ?
  rb_ivar_set(obj, id_iv_press,   INT2BOOL(event->key.state == SDL_PRESSED)); // TODO: nuke?
  rb_ivar_set(obj, id_iv_sym,     INT2FIX(event->key.keysym.sym));
  rb_ivar_set(obj, id_iv_mod,     UINT2NUM(event->key.keysym.mod));
  rb_ivar_set(obj, id_iv_unicode, UINT2NUM(event->key.keysym.unicode));
  return obj;
}

static VALUE Event__keydown(SDL_Event *event) {
  return __new_key_event(cEventKeydown, event);
}

static VALUE Event__keyup(SDL_Event *event) {
  return __new_key_event(cEventKeyup, event);
}

static VALUE Event__mousemove(SDL_Event *event) {
  VALUE obj = rb_obj_alloc(cEventMousemove);

  rb_ivar_set(obj, id_iv_state, INT2FIX(event->motion.state));
  rb_ivar_set(obj, id_iv_x,     INT2FIX(event->motion.x));
  rb_ivar_set(obj, id_iv_y,     INT2FIX(event->motion.y));
  rb_ivar_set(obj, id_iv_xrel,  INT2FIX(event->motion.xrel));
  rb_ivar_set(obj, id_iv_yrel,  INT2FIX(event->motion.yrel));

  return obj;
}

static VALUE __new_mouse_event(VALUE klass, SDL_Event *event)
{
  VALUE obj = rb_obj_alloc(klass);

  rb_ivar_set(obj, id_iv_button, INT2FIX(event->button.button));
  rb_ivar_set(obj, id_iv_press,  INT2BOOL(event->button.state == SDL_PRESSED));
  rb_ivar_set(obj, id_iv_x,      INT2FIX(event->button.x));
  rb_ivar_set(obj, id_iv_y,      INT2FIX(event->button.y));

  return obj;
}

static VALUE Event__mousedown(SDL_Event *event) {
  return __new_mouse_event(cEventMousedown, event);
}

static VALUE Event__mouseup(SDL_Event *event) {
  return __new_mouse_event(cEventMouseup, event);
}

//// SDL::Key methods:

static VALUE Key_s_press_p(VALUE mod, VALUE keysym) {
  UNUSED(mod);
  int sym = NUM2INT(keysym);

  if (SDLK_FIRST >= sym || sym >= SDLK_LAST)
    rb_raise(eSDLError, "%d is out of key", sym);

  if (!key_state)
    rb_raise(eSDLError,
             "You should call SDL::Key#scan before calling SDL::Key#press?");

  return INT2BOOL(key_state[sym]);
}

static VALUE Key_s_scan(VALUE mod) {
  UNUSED(mod);

  key_state = SDL_GetKeyState(NULL);
  mod_state = SDL_GetModState();

  return Qnil;
}

//// SDL::Mouse methods:

static VALUE Mouse_s_state(VALUE mod) {
  UNUSED(mod);

  int x,y;
  Uint8 result = SDL_GetMouseState(&x, &y);

  return rb_ary_new3(5,
                     INT2FIX(x),
                     INT2FIX(y),
                     INT2BOOL(result&SDL_BUTTON_LMASK),
                     INT2BOOL(result&SDL_BUTTON_MMASK),
                     INT2BOOL(result&SDL_BUTTON_RMASK));
}


//// SDL::PixelFormat methods:

static void _PixelFormat_free(void* p) {
  if (is_quit) return;
  if (!p) return;

  SDL_PixelFormat *format = p;

  if (format->palette) {
    free(format->palette->colors);
    free(format->palette);
  }

  free(format);
}

static void _PixelFormat_mark(void* p) {
  UNUSED(p);
}

static size_t _PixelFormat_memsize(const void *p) {
  return p ? sizeof(struct SDL_PixelFormat) : 0;
}

static VALUE PixelFormat_map_rgba(VALUE self, VALUE r, VALUE g, VALUE b, VALUE a) {
  DEFINE_SELF(PixelFormat, format, self);

  return UINT2NUM(SDL_MapRGBA(format,
                              NUM2UINT8(r), NUM2UINT8(g),
                              NUM2UINT8(b), NUM2UINT8(a)));
}

static VALUE PixelFormat_get_rgb(VALUE self, VALUE pixel) {
  DEFINE_SELF(PixelFormat, format, self);
  Uint8 r, g, b;

  SDL_GetRGB(NUM2UINT(pixel), format, &r, &g, &b);

  return rb_ary_new3(3, UINT2NUM(r), UINT2NUM(g), UINT2NUM(b));
}

static VALUE PixelFormat_colorkey(VALUE self) {
  DEFINE_SELF(PixelFormat, format, self);

  return UINT2NUM(format->colorkey);
}

static VALUE PixelFormat_alpha(VALUE self) {
  DEFINE_SELF(PixelFormat, format, self);

  return UINT2NUM(format->alpha);
}

//// SDL::Screen methods:

static VALUE Screen_s_open(VALUE klass, VALUE w, VALUE h, VALUE bpp, VALUE flags) {
  UNUSED(klass);
  SDL_Surface *screen;

  screen = SDL_SetVideoMode(NUM2INT(w), NUM2INT(h), NUM2INT(bpp), NUM2UINT(flags));

  if (!screen)
    rb_raise(eSDLError, "Couldn't set %dx%d %d bpp video mode: %s",
             NUM2INT(w), NUM2INT(h), NUM2INT(bpp), SDL_GetError());

  return TypedData_Wrap_Struct(cScreen, &_Surface_type, screen);
}

static VALUE Screen_flip(VALUE self) {
  DEFINE_SELF(Surface, surface, self);

  if (SDL_Flip(surface) < 0)
    FAILURE("Screen#flip");

  return Qnil;
}

static VALUE Screen_update(VALUE self, VALUE x, VALUE y, VALUE w, VALUE h) {
  DEFINE_SELF(Surface, surface, self);

  SDL_UpdateRect(surface,
                 NUM2SINT32(x), NUM2SINT32(y),
                 NUM2UINT32(w), NUM2UINT32(h));

  return Qnil;
}

//// SDL::Surface methods:

static void _Surface_free(void* surface) {
  if (is_quit) return;
  if (surface) SDL_FreeSurface(surface);
}

static void _Surface_mark(void* surface) {
  UNUSED(surface);
}

static size_t _Surface_memsize(const void *p) {
  return p ? sizeof(struct SDL_Surface) : 0;
}

static VALUE Surface_s_blit(VALUE self,
                            VALUE src, VALUE srcX, VALUE srcY, VALUE srcW, VALUE srcH,
                            VALUE dst, VALUE dstX, VALUE dstY) {
  UNUSED(self);
  DEFINE_SELF(Surface, src_surface, src);
  DEFINE_SELF(Surface, dst_surface, dst);

  SDL_Rect src_rect = NewRect(srcX, srcY, srcW, srcH);
  SDL_Rect dst_rect = NewRect(dstX, dstY, srcW, srcH);
  SDL_Rect *sr      = ZERO_RECT(src_rect) ? NULL : &src_rect;
  SDL_Rect *dr      = ZERO_RECT(dst_rect) ? NULL : &dst_rect;
  int result        = SDL_BlitSurface(src_surface, sr, dst_surface, dr);

  switch (result) {
  case -1:
    FAILURE("SDL::Surface.blit");
  case -2:
    rb_raise(eSDLMem, "SDL::Surface lost video memory");
  }

  return INT2NUM(result);
}

static VALUE Surface_s_new(VALUE self, VALUE w, VALUE h, VALUE pf) {
  UNUSED(self);
  SDL_Surface* surface;

  DEFINE_SELF(PixelFormat, format, pf);

  surface = SDL_CreateRGBSurface(SDL_SWSURFACE, NUM2INT(w), NUM2INT(h),
                                 format->BitsPerPixel,
                                 format->Rmask, format->Gmask,
                                 format->Bmask, format->Amask);
  if (!surface)
    FAILURE("Surface.new");

  return TypedData_Wrap_Struct(cSurface, &_Surface_type, surface);
}

static VALUE Surface_s_load(VALUE klass, VALUE path) {
  UNUSED(klass);
  SDL_Surface *surface;

  ExportStringValue(path);

  surface = IMG_Load(RSTRING_PTR(path));

  if (!surface)
    rb_raise(eSDLError, "Couldn't load file %s : %s",
             RSTRING_PTR(path),
             SDL_GetError());

  return TypedData_Wrap_Struct(cSurface, &_Surface_type, surface);
}

static VALUE Surface_set_color_key(VALUE self, VALUE flag, VALUE key) {
  DEFINE_SELF(Surface, surface, self);

  if (SDL_SetColorKey(surface,
                      NUM2UINT(flag),
                      VALUE2COLOR(key, surface->format)) < 0)
    FAILURE("Surface#set_color_key");

  return Qnil;
}

typedef void (*sxyxyc_func)(SDL_Surface *, Sint16, Sint16, Sint16, Sint16, Uint32);
typedef void (*sxyrc_func)(SDL_Surface *, Sint16, Sint16, Sint16, Uint32);

static VALUE _draw_func_sxyrc(sxyrc_func f, VALUE self, VALUE x, VALUE y, VALUE r, VALUE c) {
  DEFINE_SELF(Surface, surface, self);

  Sint16 x1, y1, r_;
  Uint32 color;

  x1 = NUM2SINT16(x);
  y1 = NUM2SINT16(y);
  r_ = NUM2SINT16(r);
  color = VALUE2COLOR(c, surface->format);

  f(surface, x1, y1, r_, color);

  return Qnil;
}

static VALUE _draw_func_sxywhc(sxyxyc_func f, VALUE self, VALUE x, VALUE y, VALUE w, VALUE h, VALUE c) {
  DEFINE_SELF(Surface, surface, self);

  Sint16 x1, y1, x2, y2;
  Uint32 color;

  x1 = NUM2SINT16(x);
  y1 = NUM2SINT16(y);
  x2 = x1 + NUM2SINT16(w);
  y2 = y1 + NUM2SINT16(h);
  color = VALUE2COLOR(c, surface->format);

  f(surface, x1, y1, x2, y2, color);

  return Qnil;
}

static VALUE _draw_func_sxyxyc(sxyxyc_func f, VALUE self, VALUE x, VALUE y, VALUE w, VALUE h, VALUE c) {
  DEFINE_SELF(Surface, surface, self);

  Sint16 x1, y1, r1, r2;
  Uint32 color;

  x1 = NUM2SINT16(x);
  y1 = NUM2SINT16(y);
  r1 = NUM2SINT16(w);
  r2 = NUM2SINT16(h);
  color = VALUE2COLOR(c, surface->format);

  f(surface, x1, y1, r1, r2, color);

  return Qnil;
}

static VALUE Surface_draw_bezier(VALUE self,
                                 VALUE x1,  VALUE y1,
                                 VALUE cx1, VALUE cy1,
                                 VALUE cx2, VALUE cy2,
                                 VALUE x2,  VALUE y2,
                                 VALUE l,   VALUE c) {
  DEFINE_SELF(Surface, surface, self);

  sge_AABezier(surface,
               NUM2SINT16(x1), NUM2SINT16(y1),
               NUM2SINT16(cx1), NUM2SINT16(cy1),
               NUM2SINT16(cx2), NUM2SINT16(cy2),
               NUM2SINT16(x2), NUM2SINT16(y2),
               NUM2INT(l),
               VALUE2COLOR(c, surface->format));

  return Qnil;
}

DEFINE_SXYRC(draw_circle,   sge_AACircle)
DEFINE_SXYRC(fill_circle,   sge_AAFilledCircle)
DEFINE_SXYXYC(draw_line,    sge_AALine)
DEFINE_SXYXYC(fill_ellipse, sge_FilledEllipse)
DEFINE_SXYXYC(draw_ellipse, sge_Ellipse)
DEFINE_SXYWHC(draw_rect,    sge_Rect)
DEFINE_SXYWHC(fill_rect,    sge_FilledRect)

static VALUE Surface_fast_rect(VALUE self, VALUE x, VALUE y, VALUE w, VALUE h, VALUE color) {
  DEFINE_SELF(Surface, surface, self);

  SDL_Rect rect = NewRect(x, y, w, h);

  if (SDL_FillRect(surface, &rect, VALUE2COLOR(color, surface->format)) < 0)
    FAILURE("Surface#fast_rect");

  return Qnil;
}

static VALUE Surface_flags(VALUE self) {
  DEFINE_SELF(Surface, surface, self);

  return UINT2NUM(surface->flags);
}

static VALUE Surface_set_alpha(VALUE self, VALUE flag, VALUE alpha) {
  DEFINE_SELF(Surface, surface, self);

  if (SDL_SetAlpha(surface, NUM2UINT(flag), NUM2UINT8(alpha)))
    FAILURE("Surface#set_alpha");

  return Qnil;
}

static VALUE Surface_format(VALUE self) {
  DEFINE_SELF(Surface, surface, self);
  SDL_PixelFormat* format;
  SDL_Palette* palette;
  SDL_Palette* src = surface->format->palette;

  if (src) {
    palette = ALLOC(SDL_Palette);
    palette->ncolors = src->ncolors;
    palette->colors  = ALLOC_N(SDL_Color, (size_t)src->ncolors);
    MEMCPY(palette->colors, src->colors, SDL_Color, (size_t)src->ncolors);
  } else {
    palette = NULL;
  }

  VALUE ret = TypedData_Make_Struct(cPixelFormat, SDL_PixelFormat, &_PixelFormat_type, format);

  *format = *(surface->format);
  format->palette = palette;

  return ret;
}

static VALUE Surface_h(VALUE self) {
  DEFINE_SELF(Surface, surface, self);

  return INT2NUM(surface->h);
}

static VALUE Surface_index(VALUE self, VALUE x, VALUE y) {
  DEFINE_SELF(Surface, surface, self);

  return UINT2NUM(sge_GetPixel(surface,
                               NUM2SINT16(x), NUM2SINT16(y)));
}

static VALUE Surface_index_equals(VALUE self, VALUE x, VALUE y, VALUE color) {
  DEFINE_SELF(Surface, surface, self);

  sge_PutPixel(surface,
               NUM2SINT16(x), NUM2SINT16(y),
               VALUE2COLOR(color, surface->format));

  return Qnil;
}

static VALUE Surface_make_collision_map(VALUE self) {
  DEFINE_SELF(Surface, surface, self);

  sge_cdata * cdata = sge_make_cmap(surface);

  if (!cdata)
    FAILURE("Surface#make_collision_map");

  return TypedData_Wrap_Struct(cCollisionMap, &_CollisionMap_type, cdata);
}

static VALUE Surface_w(VALUE self) {
  DEFINE_SELF(Surface, surface, self);

  return INT2NUM(surface->w);
}

static VALUE Surface_transform(VALUE self, VALUE bgcolor, VALUE angle,
                               VALUE xscale, VALUE yscale, VALUE flags) {
  DEFINE_SELF(Surface, surface, self);

  SDL_Surface *result = sge_transform_surface(surface,
                                              VALUE2COLOR(bgcolor, surface->format),
                                              NUM2FLT(angle),
                                              NUM2FLT(xscale),
                                              NUM2FLT(yscale),
                                              NUM2UINT8(flags));
  if (!result)
    FAILURE("Surface#transform");

  if (SDL_SetColorKey(result,
                      SDL_SRCCOLORKEY|SDL_RLEACCEL,
                      surface->format->colorkey) < 0)
    FAILURE("Surface#transform(set_color_key)");


  if (SDL_SetAlpha(result, SDL_SRCALPHA|SDL_RLEACCEL, surface->format->alpha))
    FAILURE("Surface#transform(set_alpha)");

  return TypedData_Wrap_Struct(cSurface, &_Surface_type, result);
}

//// SDL::TTFFont methods:

static void _TTFFont_free(void* font) {
  if (is_quit) return;
  if (font) TTF_CloseFont(font);
}

static void _TTFFont_mark(void* p) {
  UNUSED(p);
}

static VALUE Font_s_open(VALUE self, VALUE path, VALUE size) {
  UNUSED(self);

  ExportStringValue(path);

  TTF_Font* font = TTF_OpenFont(RSTRING_PTR(path), NUM2UINT16(size));

  if (!font)
    FAILURE("Font.open");

  return TypedData_Wrap_Struct(cTTFFont, &_TTFFont_type, font);
}

static VALUE Font_height(VALUE self) {
  DEFINE_SELF(TTFFont, font, self);

  return INT2FIX(TTF_FontHeight(font));
}

static VALUE Font_render(VALUE self, VALUE dst, VALUE text, VALUE c) {
  DEFINE_SELF(TTFFont, font, self);
  DEFINE_SELF(Surface, surface, dst);

  SDL_Surface *result;

  SDL_Color fg = sge_GetRGB(surface, VALUE2COLOR(c, surface->format));

  ExportStringValue(text);
  result = TTF_RenderUTF8_Blended(font, StringValueCStr(text), fg);

  if (result) return TypedData_Wrap_Struct(cSurface, &_Surface_type, result);
  return Qnil;
}

static VALUE Font_draw(VALUE self, VALUE dst, VALUE text, VALUE x, VALUE y, VALUE c) {
  VALUE img = Font_render(self, dst, text, c);
  VALUE zero = INT2FIX(0);

  Surface_s_blit(cSurface, img, zero, zero, zero, zero, dst, x, y);

  return Qnil;
}

//// SDL::WM methods:

static VALUE WM_s_set_caption(VALUE mod, VALUE title, VALUE icon) {
  UNUSED(mod);
  ExportStringValue(title);
  ExportStringValue(icon);

  SDL_WM_SetCaption(StringValueCStr(title), StringValueCStr(icon));

  return Qnil;
}

// The Rest...

void Init_sdl() {

  mSDL         = rb_define_module("SDL");
  mKey         = rb_define_module_under(mSDL, "Key");
  mWM          = rb_define_module_under(mSDL, "WM");
  mMouse       = rb_define_module_under(mSDL, "Mouse");

  cAudio        = rb_define_class_under(mSDL, "Audio",        rb_cData);
  cCollisionMap = rb_define_class_under(mSDL, "CollisionMap", rb_cData);
  cEvent        = rb_define_class_under(mSDL, "Event",        rb_cObject);
  cPixelFormat  = rb_define_class_under(mSDL, "PixelFormat",  rb_cData);
  cSurface      = rb_define_class_under(mSDL, "Surface",      rb_cData);
  cTTFFont      = rb_define_class_under(mSDL, "TTF",          rb_cData); // TODO: Font

  cScreen       = rb_define_class_under(mSDL, "Screen",       cSurface);

  cEventQuit   = rb_define_class_under(cEvent, "Quit", cEvent);
  cEventKeydown = rb_define_class_under(cEvent, "Keydown", cEvent);
  cEventKeyup   = rb_define_class_under(cEvent, "Keyup", cEvent);

  cEventMousemove = rb_define_class_under(cEvent, "Mousemove", cEvent);
  cEventMousedown = rb_define_class_under(cEvent, "Mousedown", cEvent);
  cEventMouseup   = rb_define_class_under(cEvent, "Mouseup",   cEvent);

  eSDLError    = rb_define_class_under(mSDL,     "Error",           rb_eStandardError);
  eSDLMem      = rb_define_class_under(cSurface, "VideoMemoryLost", rb_eStandardError);

  //// SDL methods:

  rb_define_module_function(mSDL, "init", sdl_s_init, 1);

  //// SDL::Audio methods:

  rb_define_singleton_method(cAudio, "open", Audio_s_open, 1);
  rb_define_singleton_method(cAudio, "load", Audio_s_load, 1);
  rb_define_method(cAudio, "play", Audio_play, 0);

  //// SDL::CollisionMap methods:

  rb_define_method(cCollisionMap, "check", CollisionMap_check, 5);

  //// SDL::Event methods:

  rb_define_singleton_method(cEvent, "poll", Event_s_poll, 0);

  rb_define_attr(cEventKeydown, "press",   1, 1);
  rb_define_attr(cEventKeydown, "sym",     1, 1);
  rb_define_attr(cEventKeydown, "mod",     1, 1);
  rb_define_attr(cEventKeydown, "unicode", 1, 1);

  rb_define_attr(cEventKeyup, "press",   1, 1); // TODO: refactor, possibly subclass
  rb_define_attr(cEventKeyup, "sym",     1, 1);
  rb_define_attr(cEventKeyup, "mod",     1, 1);
  rb_define_attr(cEventKeyup, "unicode", 1, 1);

  rb_define_attr(cEventMousemove, "state", 1, 1);
  rb_define_attr(cEventMousemove, "x",     1, 1);
  rb_define_attr(cEventMousemove, "y",     1, 1);
  rb_define_attr(cEventMousemove, "xrel",  1, 1);
  rb_define_attr(cEventMousemove, "yrel",  1, 1);

  rb_define_attr(cEventMousedown, "button", 1, 1);
  rb_define_attr(cEventMousedown, "press",  1, 1);
  rb_define_attr(cEventMousedown, "x",      1, 1);
  rb_define_attr(cEventMousedown, "y",      1, 1);

  rb_define_attr(cEventMouseup,   "button", 1, 1);
  rb_define_attr(cEventMouseup,   "press",  1, 1);
  rb_define_attr(cEventMouseup,   "x",      1, 1);
  rb_define_attr(cEventMouseup,   "y",      1, 1);

  //// SDL::Key methods:

  rb_define_module_function(mKey, "press?", Key_s_press_p, 1);
  rb_define_module_function(mKey, "scan",   Key_s_scan,    0);

  //// SDL::Mouse methods:

  rb_define_module_function(mMouse, "state", Mouse_s_state, 0);

  //// SDL::PixelFormat methods:

  rb_define_method(cPixelFormat, "get_rgb",  PixelFormat_get_rgb, 1);
  rb_define_method(cPixelFormat, "map_rgba", PixelFormat_map_rgba, 4);
  rb_define_method(cPixelFormat, "colorkey", PixelFormat_colorkey, 0);
  rb_define_method(cPixelFormat, "alpha", PixelFormat_alpha, 0);

  //// SDL::Screen methods:

  rb_define_singleton_method(cScreen, "open", Screen_s_open, 4);
  rb_define_method(cScreen, "flip", Screen_flip, 0);
  rb_define_method(cScreen, "update", Screen_update, 4);

  //// SDL::Surface methods:

  rb_define_singleton_method(cSurface, "blit", Surface_s_blit, 8);
  rb_define_singleton_method(cSurface, "new", Surface_s_new, 3);
  rb_define_singleton_method(cSurface, "load", Surface_s_load, 1);
  rb_define_method(cSurface, "set_color_key",  Surface_set_color_key, 2);
  rb_define_method(cSurface, "draw_bezier",  Surface_draw_bezier,  10);
  rb_define_method(cSurface, "draw_circle",  Surface_draw_circle,  4);
  rb_define_method(cSurface, "fill_circle",  Surface_fill_circle,  4);
  rb_define_method(cSurface, "draw_ellipse", Surface_draw_ellipse, 5);
  rb_define_method(cSurface, "fill_ellipse", Surface_fill_ellipse, 5);
  rb_define_method(cSurface, "draw_line",    Surface_draw_line,    5);
  rb_define_method(cSurface, "draw_rect",    Surface_draw_rect,    5);
  rb_define_method(cSurface, "fill_rect",    Surface_fill_rect,    5);
  rb_define_method(cSurface, "fast_rect",    Surface_fast_rect,    5);
  rb_define_method(cSurface, "format",       Surface_format,       0);
  rb_define_method(cSurface, "h",            Surface_h,            0);
  rb_define_method(cSurface, "make_collision_map", Surface_make_collision_map, 0);
  rb_define_method(cSurface, "w",            Surface_w,            0);
  rb_define_method(cSurface, "[]",           Surface_index,        2);
  rb_define_method(cSurface, "[]=",          Surface_index_equals, 3);
  rb_define_method(cSurface, "transform",    Surface_transform,    5);
  rb_define_method(cSurface, "flags",        Surface_flags,        0);
  rb_define_method(cSurface, "set_alpha",    Surface_set_alpha,    2);

  //// SDL::TTFFont methods:

  rb_define_singleton_method(cTTFFont, "open", Font_s_open, 2);

  rb_define_method(cTTFFont, "height", Font_height, 0);
  rb_define_method(cTTFFont, "render", Font_render, 3);
  rb_define_method(cTTFFont, "draw",   Font_draw, 5);

  //// SDL::WM methods:

  rb_define_module_function(mWM, "set_caption", WM_s_set_caption, 2);

  //// Other Init Actions:

  sge_Lock_ON();
  sge_Update_OFF();
  SDL_EnableUNICODE(1);

  for (int i=0; i < SDL_NUMEVENTS; ++i)
    event_creators[i] = Event__null;

  // event_creators[SDL_ACTIVEEVENT]     = Event__active;
  event_creators[SDL_KEYDOWN]         = Event__keydown;
  event_creators[SDL_KEYUP]           = Event__keyup;
  event_creators[SDL_MOUSEMOTION]     = Event__mousemove;
  event_creators[SDL_MOUSEBUTTONDOWN] = Event__mousedown;
  event_creators[SDL_MOUSEBUTTONUP]   = Event__mouseup;
  event_creators[SDL_QUIT]            = Event__quit;
  // event_creators[SDL_SYSWMEVENT]      = Event__syswm;
  // event_creators[SDL_VIDEORESIZE]     = Event__videoresize;

  rb_set_end_proc(sdl__quit, 0);

  //// Simple Mapped Constants:

  INIT_ID(button);
  INIT_ID(mod);
  INIT_ID(press);
  INIT_ID(state);
  INIT_ID(sym);
  INIT_ID(unicode);
  INIT_ID(x);
  INIT_ID(xrel);
  INIT_ID(y);
  INIT_ID(yrel);

  #define DC(n) rb_define_const(mSDL, #n, UINT2NUM(SDL_##n))
  DC(DOUBLEBUF);
  DC(HWSURFACE);
  DC(INIT_EVERYTHING);
  DC(INIT_VIDEO);
  DC(RLEACCEL);
  DC(SRCALPHA);
  DC(SRCCOLORKEY);
  DC(SWSURFACE);

  // DC("ANYFORMAT");
  // DC("ASYNCBLIT");
  // DC("FULLSCREEN");
  // DC("HWACCEL");
  // DC("HWPALETTE");
  // DC("NOFRAME");
  // DC("OPENGL");
  // DC("OPENGLBLIT");
  // DC("PREALLOC");
  // DC("RESIZABLE");
  // DC("RLEACCELOK");

  //// Keyboard Constants

  #define _KEY(n, v) rb_define_const(mKey, (n), INT2NUM(v))
  #define KEY(n, v)  _KEY(n,       SDLK_##v)
  #define DK(n)      _KEY(#n,      SDLK_##n)
  #define DKP(n)     _KEY("K"#n,   SDLK_##n)
  #define DM(n)      _KEY("MOD_"#n, KMOD_##n)
  #define DR(n)      _KEY("DEFAULT_REPEAT_"#n, SDL_DEFAULT_REPEAT_##n)

  DK(UNKNOWN);   DK(FIRST);      DK(BACKSPACE); DK(TAB);       DK(CLEAR);
  DK(RETURN);    DK(PAUSE);      DK(ESCAPE);    DK(SPACE);     DK(EXCLAIM);
  DK(QUOTEDBL);  DK(HASH);       DK(DOLLAR);    DK(AMPERSAND); DK(QUOTE);
  DK(LEFTPAREN); DK(RIGHTPAREN); DK(ASTERISK);  DK(PLUS);      DK(COMMA);
  DK(MINUS);     DK(PERIOD);     DK(SLASH);     DK(QUESTION);  DK(AT);
  DK(COLON);     DK(SEMICOLON);  DK(LESS);      DK(EQUALS);    DK(GREATER);

  DKP(0); DKP(1); DKP(2); DKP(3); DKP(4); DKP(5); DKP(6); DKP(7); DKP(8); DKP(9);

  DK(LEFTBRACKET); DK(BACKSLASH); DK(RIGHTBRACKET); DK(CARET);
  DK(UNDERSCORE);  DK(BACKQUOTE); DK(DELETE);

  // Skip uppercase letters
  KEY("A", a); KEY("B", b); KEY("C", c); KEY("D", d); KEY("E", e);
  KEY("F", f); KEY("G", g); KEY("H", h); KEY("I", i); KEY("J", j);
  KEY("K", k); KEY("L", l); KEY("M", m); KEY("N", n); KEY("O", o);
  KEY("P", p); KEY("Q", q); KEY("R", r); KEY("S", s); KEY("T", t);
  KEY("U", u); KEY("V", v); KEY("W", w); KEY("X", x); KEY("Y", y);
  KEY("Z", z);

  // International keyboard syms
  DK(WORLD_0);  DK(WORLD_1);  DK(WORLD_2);  DK(WORLD_3);  DK(WORLD_4);
  DK(WORLD_5);  DK(WORLD_6);  DK(WORLD_7);  DK(WORLD_8);  DK(WORLD_9);
  DK(WORLD_10); DK(WORLD_11); DK(WORLD_12); DK(WORLD_13); DK(WORLD_14);
  DK(WORLD_15); DK(WORLD_16); DK(WORLD_17); DK(WORLD_18); DK(WORLD_19);
  DK(WORLD_20); DK(WORLD_21); DK(WORLD_22); DK(WORLD_23); DK(WORLD_24);
  DK(WORLD_25); DK(WORLD_26); DK(WORLD_27); DK(WORLD_28); DK(WORLD_29);
  DK(WORLD_30); DK(WORLD_31); DK(WORLD_32); DK(WORLD_33); DK(WORLD_34);
  DK(WORLD_35); DK(WORLD_36); DK(WORLD_37); DK(WORLD_38); DK(WORLD_39);
  DK(WORLD_40); DK(WORLD_41); DK(WORLD_42); DK(WORLD_43); DK(WORLD_44);
  DK(WORLD_45); DK(WORLD_46); DK(WORLD_47); DK(WORLD_48); DK(WORLD_49);
  DK(WORLD_50); DK(WORLD_51); DK(WORLD_52); DK(WORLD_53); DK(WORLD_54);
  DK(WORLD_55); DK(WORLD_56); DK(WORLD_57); DK(WORLD_58); DK(WORLD_59);
  DK(WORLD_60); DK(WORLD_61); DK(WORLD_62); DK(WORLD_63); DK(WORLD_64);
  DK(WORLD_65); DK(WORLD_66); DK(WORLD_67); DK(WORLD_68); DK(WORLD_69);
  DK(WORLD_70); DK(WORLD_71); DK(WORLD_72); DK(WORLD_73); DK(WORLD_74);
  DK(WORLD_75); DK(WORLD_76); DK(WORLD_77); DK(WORLD_78); DK(WORLD_79);
  DK(WORLD_80); DK(WORLD_81); DK(WORLD_82); DK(WORLD_83); DK(WORLD_84);
  DK(WORLD_85); DK(WORLD_86); DK(WORLD_87); DK(WORLD_88); DK(WORLD_89);
  DK(WORLD_90); DK(WORLD_91); DK(WORLD_92); DK(WORLD_93); DK(WORLD_94);
  DK(WORLD_95);

  // Numeric keypad
  DK(KP0); DK(KP1); DK(KP2); DK(KP3); DK(KP4);
  DK(KP5); DK(KP6); DK(KP7); DK(KP8); DK(KP9);

  DK(KP_PERIOD); DK(KP_DIVIDE); DK(KP_MULTIPLY); DK(KP_MINUS);
  DK(KP_PLUS);   DK(KP_ENTER);  DK(KP_EQUALS);

  // Arrows + Home/End pad
  DK(UP);   DK(DOWN); DK(RIGHT);  DK(LEFT); DK(INSERT);
  DK(HOME); DK(END);  DK(PAGEUP); DK(PAGEDOWN);

  // Function keys
  DK(F1);  DK(F2);  DK(F3);  DK(F4);  DK(F5);  DK(F6); DK(F7); DK(F8); DK(F9);
  DK(F10); DK(F11); DK(F12); DK(F13); DK(F14); DK(F15);

  // Key state modifier keys
  DK(NUMLOCK); DK(CAPSLOCK); DK(SCROLLOCK); DK(RSHIFT); DK(LSHIFT); DK(RCTRL);
  DK(LCTRL); DK(RALT); DK(LALT); DK(RMETA); DK(LMETA); DK(LSUPER); DK(RSUPER);
  DK(MODE);

  // Miscellaneous function keys
  DK(HELP); DK(PRINT); DK(SYSREQ); DK(BREAK);
  DK(MENU); DK(POWER); DK(EURO); DK(LAST);

  // key mods
  DM(NONE);  DM(LSHIFT); DM(RSHIFT); DM(LCTRL); DM(RCTRL); DM(LALT);     DM(RALT);
  DM(LMETA); DM(RMETA);  DM(NUM);    DM(CAPS);  DM(MODE);  DM(RESERVED); DM(CTRL);
  DM(SHIFT); DM(ALT);    DM(META);

  // key repeat constants
  DR(DELAY);
  DR(INTERVAL);
}
