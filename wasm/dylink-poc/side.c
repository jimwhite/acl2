#include <emscripten.h>
EMSCRIPTEN_KEEPALIVE int side_double(int x) { return 2 * x; }
