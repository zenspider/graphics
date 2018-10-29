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

#define FAILURE(s) rb_raise(eSDLError, "%s failed: %s", (s), SDL_GetError())
#define AUDIO_FAILURE(s) rb_raise(eSDLError, "%s failed: %s", (s), Mix_GetError())
#define TTF_FAILURE(s)   rb_raise(eSDLError, "%s failed: %s", (s), TTF_GetError())

#define SHOULD_BLEND(a) (a) != 0xff

#define DEFINE_ID(name) static ID id_iv_##name
#define INIT_ID(name) id_iv_##name = rb_intern("@"#name)

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
static VALUE mMouse;

typedef TTF_Font SDL_TTFFont;
typedef Mix_Chunk SDL_Audio;
typedef sge_cdata SDL_CollisionMap;

static ID id_H;
static ID id_W;

DEFINE_ID(renderer);
DEFINE_ID(window);
DEFINE_ID(texture);
DEFINE_ID(button);
DEFINE_ID(mod);
DEFINE_ID(press);
DEFINE_ID(state);
DEFINE_ID(sym);
DEFINE_ID(x);
DEFINE_ID(xrel);
DEFINE_ID(y);
DEFINE_ID(yrel);

DEFINE_CLASS(Audio,        "SDL::Audio")
DEFINE_CLASS(Surface,      "SDL::Surface")
DEFINE_CLASS(Texture,      "SDL::Texture")   // TODO: I kinda want these hidden
DEFINE_CLASS(Renderer,     "SDL::Renderer")  // TODO: I kinda want these hidden
DEFINE_CLASS(Window,       "SDL::Window")    // TODO: I kinda want these hidden
DEFINE_CLASS(CollisionMap, "SDL::CollisionMap")
DEFINE_CLASS(PixelFormat,  "SDL::PixelFormat")
DEFINE_CLASS_0(TTFFont,    "SDL::TTFFont")

#define SDL_NUMEVENTS 0xFFFF // HACK
typedef VALUE (*event_creator)(SDL_Event *);
static event_creator event_creators[SDL_NUMEVENTS];

static int is_quit = 0;
static int key_state_len = 0;
static Uint8* key_state = NULL;
static SDL_Keymod mod_state;

void Init_sdl(void);

//// Misc / Utility functions:

static void rb_const_reset(VALUE mod, ID id, VALUE val) { // avoids warnings
  rb_const_remove(mod, id);
  rb_const_set(mod, id, val);
}

// TODO: collapse to one format
static Uint32 VALUE2COLOR(VALUE color, SDL_PixelFormat *format) {
  // TODO: reverse and use FIXNUM_P ?
  if (rb_obj_is_kind_of(color, rb_cArray)) {
    rb_warn("when are colors arrays?!??"); // TODO: remove
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

  SDL_Rect r;
  if (SDL_GetDisplayBounds(0, &r) != 0) {
    rb_raise(eSDLError, "Failure calling SDL_GetDisplayBounds()");
    return 1;
  }

  rb_const_reset(cScreen, id_W, UINT2NUM(r.w));
  rb_const_reset(cScreen, id_H, UINT2NUM(r.h));

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
    AUDIO_FAILURE("Audio.load");

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

  if (!key_state)
    rb_raise(eSDLError,
             "You should call SDL::Key#scan before calling SDL::Key#press?");

  if (0 >= sym || sym >= key_state_len)
    rb_raise(eSDLError, "%d is out of key (%d)", sym, key_state_len);

  return INT2BOOL(key_state[sym]);
}

static VALUE Key_s_scan(VALUE mod) {
  UNUSED(mod);

  key_state = (Uint8 *) SDL_GetKeyboardState(&key_state_len);
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

static VALUE PixelFormat_get_rgba(VALUE self, VALUE pixel) {
  DEFINE_SELF(PixelFormat, format, self);
  Uint8 r, g, b, a;

  SDL_GetRGBA(NUM2UINT(pixel), format, &r, &g, &b, &a);

  return rb_ary_new3(4, UINT2NUM(r), UINT2NUM(g), UINT2NUM(b), UINT2NUM(a));
}

//// SDL::Screen methods:

static VALUE Screen_s_open(VALUE klass, VALUE w_, VALUE h_, VALUE bpp_, VALUE flags_) {
  UNUSED(klass);
  SDL_Window   *window;
  SDL_Renderer *renderer;
  SDL_Surface  *surface;

  int w        = NUM2INT(w_);
  int h        = NUM2INT(h_);
  int bpp      = NUM2INT(bpp_);
  Uint32 flags = NUM2UINT32(flags_);

  if (!bpp) bpp = 32; // TODO: remove bpp option and always be 32?

  window = SDL_CreateWindow("", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                            w, h,
                            flags);
  if (!window) FAILURE("Screen.open(CreateWindow)");

  renderer = SDL_CreateRenderer(window, -1,
                                SDL_RENDERER_PRESENTVSYNC|SDL_RENDERER_ACCELERATED);
  if (!renderer) FAILURE("Screen.open(CreateRenderer)");

  surface = SDL_CreateRGBSurfaceWithFormat(0, w, h, bpp,
                                           SDL_PIXELFORMAT_RGBA32);
  if (!surface) FAILURE("Screen.open(CreateRGBSurface)");

  SDL_Texture *texture = SDL_CreateTexture(renderer,
                                           SDL_PIXELFORMAT_RGBA32,
                                           SDL_TEXTUREACCESS_STREAMING,
                                           w, h);
  if (!texture)
    FAILURE("Screen.open(CreateTexture)");

  SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "linear");
  SDL_RenderSetLogicalSize(renderer, w, h);

  // TODO: make this a cSurface? Moves Screen#flip to Surface#flip
  VALUE vsurface  = TypedData_Wrap_Struct(cScreen,   &_Surface_type,  surface);
  VALUE vwindow   = TypedData_Wrap_Struct(cWindow,   &_Window_type,   window);
  VALUE vrenderer = TypedData_Wrap_Struct(cRenderer, &_Renderer_type, renderer);
  VALUE vtexture  = TypedData_Wrap_Struct(cTexture,  &_Texture_type,  texture);

  rb_ivar_set(vsurface, id_iv_renderer, vrenderer);
  rb_ivar_set(vsurface, id_iv_texture,  vtexture);
  rb_ivar_set(vsurface, id_iv_window,   vwindow);

  return vsurface;
}

static VALUE Screen_flip(VALUE self) {
  DEFINE_SELF(Surface,  surface,  self);
  DEFINE_SELF(Renderer, renderer, rb_ivar_get(self, id_iv_renderer));
  DEFINE_SELF(Texture,  texture,  rb_ivar_get(self, id_iv_texture));

  // TODO: there's a note about this being for fairly static textures...
  if (SDL_UpdateTexture(texture, NULL, surface->pixels, surface->pitch))
    FAILURE("Screen#flip: SDL_UpdateTexture");
  if (SDL_RenderClear(renderer))
    FAILURE("Screen#flip: SDL_RenderClear");
  if (SDL_RenderCopy(renderer, texture, NULL, NULL))
    FAILURE("Screen#flip: SDL_RenderCopy");

  SDL_RenderPresent(renderer);

  return Qnil;
}

static VALUE Screen_set_title(VALUE self, VALUE title) {
  DEFINE_SELF(Window, window, rb_ivar_get(self, id_iv_window));

  ExportStringValue(title);

  SDL_SetWindowTitle(window, StringValueCStr(title));

  return Qnil;
}

static VALUE Screen_update(VALUE self, VALUE x, VALUE y, VALUE w, VALUE h) {
  rb_raise(eSDLError, "Do not call Screen#update");
  return Qnil;
}

//// SDL::Surface methods:

static void _Surface_free(void* surface) {
  if (is_quit) return;
  if (surface) SDL_FreeSurface(surface);
}

static void _Surface_mark(void* surface) {
  UNUSED(surface);
  // TODO: might need to mark ivars? I don't think so tho
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

static VALUE Surface_color_key(VALUE self) {
  DEFINE_SELF(Surface, surface, self);

  Uint32 colorkey = 0;

  if (SDL_GetColorKey(surface, &colorkey))
    rb_raise(eSDLError, "Couldn't get color_key: %s", SDL_GetError());

  return UINT2NUM(colorkey);
}

static VALUE Surface_set_color_key(VALUE self, VALUE flag, VALUE key) {
  DEFINE_SELF(Surface, surface, self);

  if (SDL_SetColorKey(surface,
                      NUM2UINT(flag),
                      VALUE2COLOR(key, surface->format)) < 0)
    FAILURE("Surface#set_color_key");

  return Qnil;
}

#define DEFINE_WRAP12(name)                                \
  void wrap_##name(SDL_Surface* a,                         \
                   Sint16 b, Sint16 c, Sint16 d, Sint16 e, \
                   Sint16 f, Sint16 g, Sint16 h, Sint16 i, \
                   int j,                                  \
                   Uint32 k, Uint8 l) { name(a, b, c, d, e, f, g, h, i, j, k); }
#define DEFINE_WRAP7(name)                                 \
  void wrap_##name(SDL_Surface* a,                         \
                   Sint16 b, Sint16 c, Sint16 d, Sint16 e, \
                   Uint32 f, Uint8 g) { name(a, b, c, d, e, f); }
#define DEFINE_WRAP6(name)                                 \
  void wrap_##name(SDL_Surface* a,                         \
                   Sint16 b, Sint16 c, Sint16 d,           \
                   Uint32 e, Uint8 f) { name(a, b, c, d, e); }

#define IDX2(a, b)                 (!!(a))<<1 | !!(b);
#define IDX3(a, b, c) (!!(a))<<2 | (!!(b))<<1 | !!(c);

typedef void (*f_sxyxyxyxylca)(SDL_Surface*,
                               Sint16, Sint16, Sint16, Sint16,
                               Sint16, Sint16, Sint16, Sint16,
                               int,
                               Uint32, Uint8);
typedef void (*f_sxyxyca)(SDL_Surface*,
                          Sint16, Sint16, Sint16, Sint16,
                          Uint32, Uint8);
typedef void (*f_sxyrca)(SDL_Surface*,
                          Sint16, Sint16, Sint16,
                          Uint32, Uint8);

static
Uint8 my_GetAlpha(VALUE c, SDL_Surface* s) {
  Uint8 q, a;
  SDL_GetRGBA(NUM2UINT(c), s->format, &q, &q, &q, &a);
  return a;
}

DEFINE_WRAP12(sge_Bezier)
DEFINE_WRAP12(sge_AABezier)

static f_sxyxyxyxylca f_bezier[] = { &wrap_sge_Bezier,
                                     &wrap_sge_AABezier,
                                     &sge_BezierAlpha,
                                     &sge_AABezierAlpha };

static VALUE Surface_draw_bezier(VALUE self,
                                 VALUE x1,  VALUE y1,
                                 VALUE cx1, VALUE cy1,
                                 VALUE cx2, VALUE cy2,
                                 VALUE x2,  VALUE y2,
                                 VALUE l,
                                 VALUE c,
                                 VALUE aa) {
  DEFINE_SELF(Surface, surface, self);

  Uint8 a   = my_GetAlpha(c, surface);
  Uint8 idx = IDX2(SHOULD_BLEND(a), RTEST(aa));

  f_bezier[idx](surface,
                NUM2SINT16(x1),  NUM2SINT16(y1),
                NUM2SINT16(cx1), NUM2SINT16(cy1),
                NUM2SINT16(cx2), NUM2SINT16(cy2),
                NUM2SINT16(x2),  NUM2SINT16(y2),
                NUM2INT(l),
                VALUE2COLOR(c, surface->format),
                a);

  return Qnil;
}

DEFINE_WRAP6(sge_Circle)
DEFINE_WRAP6(sge_FilledCircle)
DEFINE_WRAP6(sge_AACircle)
DEFINE_WRAP6(sge_AAFilledCircle)

static f_sxyrca f_circle[] = { &wrap_sge_Circle,
                               &wrap_sge_FilledCircle,
                               &wrap_sge_AACircle,
                               &wrap_sge_AAFilledCircle,
                               &sge_CircleAlpha,
                               &sge_FilledCircleAlpha,
                               &sge_AACircleAlpha,
                               &sge_FilledCircleAlpha }; // FIX? n/a

static VALUE Surface_draw_circle(VALUE self,
                                 VALUE x,  VALUE y,
                                 VALUE r,
                                 VALUE c,
                                 VALUE aa, VALUE f) {
  DEFINE_SELF(Surface, surface, self);

  Uint8 a   = my_GetAlpha(c, surface);
  Uint8 idx = IDX3(SHOULD_BLEND(a), RTEST(aa), RTEST(f));

  // TODO: seems like SGE isn't keeping up with SDL's RGBA support
  f_circle[idx](surface,
                NUM2SINT16(x), NUM2SINT16(y),
                NUM2SINT16(r),
                VALUE2COLOR(c, surface->format),
                a);

  return Qnil;
}

DEFINE_WRAP7(sge_Ellipse)
DEFINE_WRAP7(sge_FilledEllipse)
DEFINE_WRAP7(sge_AAEllipse)
DEFINE_WRAP7(sge_AAFilledEllipse)

static f_sxyxyca f_ellipse[] = { &wrap_sge_Ellipse,
                                 &wrap_sge_FilledEllipse,
                                 &wrap_sge_AAEllipse,
                                 &wrap_sge_AAFilledEllipse,
                                 &sge_EllipseAlpha,
                                 &sge_FilledEllipseAlpha,
                                 &sge_AAEllipseAlpha,
                                 &sge_FilledEllipseAlpha }; // FIX? n/a

static VALUE Surface_draw_ellipse(VALUE self,
                                  VALUE x,  VALUE y,
                                  VALUE rx, VALUE ry,
                                  VALUE c,
                                  VALUE aa, VALUE f) {
  DEFINE_SELF(Surface, surface, self);

  Uint8 a   = my_GetAlpha(c, surface);
  Uint8 idx = IDX3(SHOULD_BLEND(a), RTEST(aa), RTEST(f));

  f_ellipse[idx](surface,
                 NUM2SINT16(x),
                 NUM2SINT16(y),
                 NUM2SINT16(rx),
                 NUM2SINT16(ry),
                 VALUE2COLOR(c, surface->format),
                 a);

  return Qnil;
}

DEFINE_WRAP7(sge_Line);
DEFINE_WRAP7(sge_AALine);

static f_sxyxyca f_line[] = { &wrap_sge_Line,
                              &wrap_sge_AALine,
                              &sge_LineAlpha,
                              &sge_AALineAlpha };

static VALUE Surface_draw_line(VALUE self,
                               VALUE x1, VALUE y1,
                               VALUE x2, VALUE y2,
                               VALUE c,
                               VALUE aa) {
  DEFINE_SELF(Surface, surface, self);

  Uint8 a = my_GetAlpha(c, surface);

  Uint8 idx = IDX2(SHOULD_BLEND(a), RTEST(aa));

  f_line[idx](surface,
              NUM2SINT16(x1),
              NUM2SINT16(y1),
              NUM2SINT16(x2),
              NUM2SINT16(y2),
              VALUE2COLOR(c, surface->format),
              NUM2UINT8(a));

  return Qnil;
}

DEFINE_WRAP7(sge_Rect);
DEFINE_WRAP7(sge_FilledRect);

static f_sxyxyca f_rect[] = { &wrap_sge_Rect,
                              &wrap_sge_FilledRect,
                              &sge_RectAlpha,
                              &sge_FilledRectAlpha };

static VALUE Surface_draw_rect(VALUE self,
                               VALUE x_, VALUE y_,
                               VALUE w_, VALUE h_,
                               VALUE c,
                               VALUE f) {
  DEFINE_SELF(Surface, surface, self);

  Sint16 x1 = NUM2SINT16(x_);
  Sint16 y1 = NUM2SINT16(y_);
  Sint16 x2 = NUM2SINT16(w_) + x1;
  Sint16 y2 = NUM2SINT16(h_) + y1;
  Uint8 a   = my_GetAlpha(c, surface);
  Uint8 idx = IDX2(SHOULD_BLEND(a), RTEST(f));

  f_rect[idx](surface, x1, y1, x2, y2,
              VALUE2COLOR(c, surface->format),
              a);

  return Qnil;
}

static VALUE Surface_fast_rect(VALUE self, VALUE x, VALUE y, VALUE w, VALUE h, VALUE color) {
  DEFINE_SELF(Surface, surface, self);

  SDL_Rect rect = NewRect(x, y, w, h);

  if (SDL_FillRect(surface, &rect, VALUE2COLOR(color, surface->format)) < 0)
    FAILURE("Surface#fast_rect");

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
                                              NUM2UINT8(flags)|SGE_TAA|SGE_TSAFE);
  if (!result)
    FAILURE("Surface#transform");

  Uint8 alpha;
  if (SDL_GetSurfaceAlphaMod(surface, &alpha))
    FAILURE("Surface#transform(get_alpha)");

  if (SDL_SetSurfaceAlphaMod(result, alpha))
    FAILURE("Surface#transform(set_alpha)");

  return TypedData_Wrap_Struct(cSurface, &_Surface_type, result);
}

static VALUE Surface_save(VALUE self, VALUE path) {
  DEFINE_SELF(Surface, surface, self);

  return INT2NUM(IMG_SavePNG(surface, RSTRING_PTR(path)));
}

//// SDL::Renderer methods:

static void _Renderer_free(void* renderer) {
  if (is_quit) return;
  if (renderer) SDL_DestroyRenderer(renderer);
}

static void _Renderer_mark(void* renderer) {
  UNUSED(renderer);
}

static size_t _Renderer_memsize(const void *p) {
  return p ? sizeof(void *) : 0; // HACK: SDL_Renderer is opaque
}

//// SDL::Texture methods:

static void _Texture_free(void* texture) {
  if (is_quit) return;
  if (texture) SDL_DestroyTexture(texture);
}

static void _Texture_mark(void* texture) {
  UNUSED(texture);
}

static size_t _Texture_memsize(const void *p) {
  return p ? sizeof(void*) : 0; // HACK: SDL_Texture is opaque
}

//// SDL::Window methods:

static void _Window_free(void* Window) {
  if (is_quit) return;
  if (Window) SDL_DestroyWindow(Window);
}

static void _Window_mark(void* Window) {
  UNUSED(Window);
}

static size_t _Window_memsize(const void *p) {
  return p ? sizeof(void *) : 0; // HACK: SDL_Window is opaque
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
  SDL_Color fg;

  SDL_GetRGBA(VALUE2COLOR(c, surface->format), surface->format,
              &(fg.r), &(fg.g), &(fg.b), &(fg.a));

  ExportStringValue(text);
  result = TTF_RenderUTF8_Blended(font, StringValueCStr(text), fg);

  if (!result)
    TTF_FAILURE("Font.render");

  if (result) return TypedData_Wrap_Struct(cSurface, &_Surface_type, result);
  return Qnil;
}

static VALUE Font_draw(VALUE self, VALUE dst, VALUE text, VALUE x, VALUE y, VALUE c) {
  VALUE img = Font_render(self, dst, text, c);
  VALUE zero = INT2FIX(0);

  Surface_s_blit(cSurface, img, zero, zero, zero, zero, dst, x, y);

  return Qnil;
}

static VALUE Font_text_size(VALUE self, VALUE text) {
  DEFINE_SELF(TTFFont, font, self);
  int w = 1, h = 2, result;

  ExportStringValue(text);
  result = TTF_SizeText(font, StringValueCStr(text), &w, &h);

  if (!result) {
    return rb_ary_new_from_args(2, INT2FIX(w), INT2FIX(h));
  } else {
    FAILURE("SDL::TTF#text_size");
  }
}

// The Rest...

void Init_sdl() {

  mSDL         = rb_define_module("SDL");
  mKey         = rb_define_module_under(mSDL, "Key");
  mMouse       = rb_define_module_under(mSDL, "Mouse");

  cAudio        = rb_define_class_under(mSDL, "Audio",        rb_cData);
  cCollisionMap = rb_define_class_under(mSDL, "CollisionMap", rb_cData);
  cEvent        = rb_define_class_under(mSDL, "Event",        rb_cObject);
  cPixelFormat  = rb_define_class_under(mSDL, "PixelFormat",  rb_cData);
  cSurface      = rb_define_class_under(mSDL, "Surface",      rb_cData);
  cTTFFont      = rb_define_class_under(mSDL, "TTF",          rb_cData); // TODO: Font

  cScreen       = rb_define_class_under(mSDL, "Screen",       cSurface);
  cRenderer     = rb_define_class_under(mSDL, "Renderer",     cSurface);
  cWindow       = rb_define_class_under(mSDL, "Window",       cSurface);
  cTexture      = rb_define_class_under(mSDL, "Texture",      cSurface);

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

  rb_define_method(cPixelFormat, "get_rgba", PixelFormat_get_rgba, 1);
  rb_define_method(cPixelFormat, "map_rgba", PixelFormat_map_rgba, 4);

  //// SDL::Screen methods:

  rb_define_singleton_method(cScreen, "open", Screen_s_open, 4);
  rb_define_method(cScreen, "flip", Screen_flip, 0);
  rb_define_method(cScreen, "title=", Screen_set_title, 1);
  rb_define_method(cScreen, "update", Screen_update, 4);

  id_W = rb_intern("W");
  id_H = rb_intern("H");
  rb_const_set(cScreen, id_W, Qnil);
  rb_const_set(cScreen, id_H, Qnil);

  //// SDL::Surface methods:

  rb_define_singleton_method(cSurface, "blit", Surface_s_blit, 8);
  rb_define_singleton_method(cSurface, "new", Surface_s_new, 3);
  rb_define_singleton_method(cSurface, "load", Surface_s_load, 1);
  rb_define_method(cSurface, "color_key",     Surface_color_key, 0);
  rb_define_method(cSurface, "set_color_key", Surface_set_color_key, 2);
  rb_define_method(cSurface, "draw_bezier",  Surface_draw_bezier, 11);
  rb_define_method(cSurface, "draw_circle",  Surface_draw_circle,  6);
  rb_define_method(cSurface, "draw_ellipse", Surface_draw_ellipse, 7);
  rb_define_method(cSurface, "draw_line",    Surface_draw_line,    6);
  rb_define_method(cSurface, "draw_rect",    Surface_draw_rect,    6);
  rb_define_method(cSurface, "fast_rect",    Surface_fast_rect,    5);
  rb_define_method(cSurface, "format",       Surface_format,       0);
  rb_define_method(cSurface, "h",            Surface_h,            0);
  rb_define_method(cSurface, "make_collision_map", Surface_make_collision_map, 0);
  rb_define_method(cSurface, "w",            Surface_w,            0);
  rb_define_method(cSurface, "[]",           Surface_index,        2);
  rb_define_method(cSurface, "[]=",          Surface_index_equals, 3);
  rb_define_method(cSurface, "transform",    Surface_transform,    5);
  rb_define_method(cSurface, "save",         Surface_save,         1);

  //// SDL::TTFFont methods:

  rb_define_singleton_method(cTTFFont, "open", Font_s_open, 2);

  rb_define_method(cTTFFont, "height", Font_height, 0);
  rb_define_method(cTTFFont, "render", Font_render, 3);
  rb_define_method(cTTFFont, "draw",   Font_draw, 5);
  rb_define_method(cTTFFont, "text_size", Font_text_size, 1);

  //// Other Init Actions:

  sge_Lock_ON();
  sge_Update_OFF();

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

  // TODO: maybe pause/unpause automatically instead of chewing CPU?
  // SDL_APP_DIDENTERBACKGROUND
  // SDL_APP_DIDENTERFOREGROUND

  rb_set_end_proc(sdl__quit, 0);

  //// Simple Mapped Constants:

  INIT_ID(renderer);
  INIT_ID(window);
  INIT_ID(texture);
  INIT_ID(button);
  INIT_ID(mod);
  INIT_ID(press);
  INIT_ID(state);
  INIT_ID(sym);
  INIT_ID(x);
  INIT_ID(xrel);
  INIT_ID(y);
  INIT_ID(yrel);

  #define DC(n) rb_define_const(mSDL, #n, UINT2NUM(SDL_##n))
  DC(INIT_EVERYTHING);
  DC(INIT_VIDEO); // TODO: phase out? it's in the tests...
  DC(TRUE);

  #define DW(n) rb_define_const(mSDL, #n, UINT2NUM(SDL_WINDOW_##n))
  DW(FULLSCREEN);
  DW(OPENGL);
  DW(SHOWN);
  DW(HIDDEN);
  DW(BORDERLESS);
  DW(RESIZABLE);
  DW(MINIMIZED);
  DW(MAXIMIZED);
  DW(INPUT_GRABBED);
  DW(INPUT_FOCUS);
  DW(MOUSE_FOCUS);
  DW(FULLSCREEN_DESKTOP);
  DW(FOREIGN);
  DW(ALLOW_HIGHDPI);

  //// Keyboard Constants

  #define _KEY(n, v) rb_define_const(mKey, (n), INT2NUM(v))
  #define KEY(n, v)  _KEY(n,       SDLK_##v)
  #define DK(n)      _KEY(#n,      SDLK_##n)
  #define DKP(n)     _KEY("K"#n,   SDLK_##n)
  #define DM(n)      _KEY("MOD_"#n, KMOD_##n)

  DK(UNKNOWN);                   DK(BACKSPACE); DK(TAB);       DK(CLEAR);
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

  // Numeric keypad
  DK(KP_0); DK(KP_1); DK(KP_2); DK(KP_3); DK(KP_4);
  DK(KP_5); DK(KP_6); DK(KP_7); DK(KP_8); DK(KP_9);

  DK(KP_PERIOD); DK(KP_DIVIDE); DK(KP_MULTIPLY); DK(KP_MINUS);
  DK(KP_PLUS);   DK(KP_ENTER);  DK(KP_EQUALS);

  // Arrows + Home/End pad
  DK(UP);   DK(DOWN); DK(RIGHT);  DK(LEFT); DK(INSERT);
  DK(HOME); DK(END);  DK(PAGEUP); DK(PAGEDOWN);

  // Function keys
  DK(F1);  DK(F2);  DK(F3);  DK(F4);  DK(F5);  DK(F6); DK(F7); DK(F8); DK(F9);
  DK(F10); DK(F11); DK(F12); DK(F13); DK(F14); DK(F15);

  // Key state modifier keys
  DK(CAPSLOCK); DK(SCROLLLOCK); DK(RSHIFT); DK(LSHIFT); DK(RCTRL);
  DK(LCTRL); DK(RALT); DK(LALT); DK(RGUI); DK(LGUI); DK(MODE);

  // Miscellaneous function keys
  DK(HELP); DK(SYSREQ); DK(MENU); DK(POWER);

  // key mods
  DM(NONE);  DM(LSHIFT); DM(RSHIFT); DM(LCTRL); DM(RCTRL); DM(LALT);     DM(RALT);
  DM(LGUI);  DM(RGUI);   DM(NUM);    DM(CAPS);  DM(MODE);  DM(RESERVED); DM(CTRL);
  DM(SHIFT); DM(ALT);    DM(GUI);
}
