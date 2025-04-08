#include "constants.hpp"
#include "handle_window.hpp"
#include "network.hpp"
#include <Windows.h>

struct Buffer {
    uint8_t* pixels;
    HBITMAP bitmap = 0;
    HDC frame_device_context = 0;
    int width;
    int height;
    BITMAPINFO bitmap_info = {};
};

extern "C" void initialize_device_context(Buffer& buffer, int width, int height);