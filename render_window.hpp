#include <SFML/Graphics.hpp>
#include <SFML/Window.hpp>
#include <exception>
#include <iostream>
#include <cstdint>
#include <cassert>
#include <fstream>
#include "constants.hpp"

// extern "C" void clear_draw_region(uint8_t* buffer);

void clear_draw_region(uint8_t* buffer);

void quantize_screen(uint8_t* in_buffer, uint8_t* out_buffer);

void duplicate(uint8_t* in_buffer, uint8_t* out_buffer);

void update_quantized_pixel(uint8_t* buffer, int x, int y);

void update(uint8_t* buffer, int x, int y);

void load_digit_image(uint8_t* image_buffer);

void draw_circle(uint8_t* buffer, int x, int y, int r);