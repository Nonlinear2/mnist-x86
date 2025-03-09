#include <SFML/Graphics.hpp>
#include <SFML/Window.hpp>
#include <exception>
#include <iostream>
#include <cstdint>
#include <cassert>
#include <fstream>
#include "constants.hpp"

// extern "C" void clear_draw_region(uint8_t* buffer);

void draw_pixel(uint8_t* draw_buffer, int x, int y, int value);

void draw_pixel_on_digit(uint8_t* digits_buffer, int x, int y, int value);

void draw_pixel_on_digit_safe(uint8_t* digits_buffer, int x, int y, int value);

void clear_draw_region(uint8_t* draw_buffer);

void get_draw_region_data(uint8_t* draw_buffer, uint8_t* mnist_buffer);

// extern "C" void update_draw_region_pixel(uint8_t* draw_buffer, int x, int y);
void update_draw_region_pixel(uint8_t* draw_buffer, int x, int y);

void update_on_mouse_click(uint8_t* draw_buffer, int x, int y);

void load_digit_image(uint8_t* digits_buffer);

void draw_circle(uint8_t* digits_buffer, int x, int y, int r);