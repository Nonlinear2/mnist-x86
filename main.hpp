#include "constants.hpp"
#include "handle_window.hpp"
#include "network.hpp"
#include <Windows.h>

struct Buffer {
    int width;
    int height;
    uint8_t* pixels;
    BITMAPINFO bitmap_info = {};
    HBITMAP bitmap = 0;
    HDC frame_device_context = 0;
};

extern "C" void initialize_device_context(Buffer& buffer, int width, int height);