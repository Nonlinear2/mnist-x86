#include <SFML/Graphics.hpp>
#include <SFML/Window.hpp>
#include <exception>
#include <iostream>
#include <cstdint>
#include <cassert>
#include <fstream>
#include "constants.hpp"

extern "C" void draw_pixel(uint8_t* draw_buffer, int x, int y, uint8_t value);
// void draw_pixel(uint8_t* draw_buffer, int x, int y, uint8_t value);

extern "C" void draw_square(uint8_t* draw_buffer, int x, int y);
// void draw_square(uint8_t* draw_buffer, int x, int y);

extern "C" void clear_draw_region(uint8_t* buffer);
// void clear_draw_region(uint8_t* draw_buffer);

extern "C" void get_draw_region_features(uint8_t* draw_buffer, uint8_t* mnist_buffer);
// void get_draw_region_features(uint8_t* draw_buffer, uint8_t* mnist_buffer);

extern "C" void update_on_mouse_click(uint8_t* draw_buffer, int x, int y);
// void update_on_mouse_click(uint8_t* draw_buffer, int x, int y);

void load_digit_image(uint8_t* digits_buffer);

extern "C" void draw_pixel_on_digits(uint8_t* digits_buffer, int x, int y, int value);
// void draw_pixel_on_digits(uint8_t* digits_buffer, int x, int y, int value);

void draw_circle_on_digits(uint8_t* digits_buffer, int x, int y, int r);