#include <SFML/Graphics.hpp>
#include <SFML/Window.hpp>
#include <exception>
#include <iostream>
#include <cstdint>

extern "C" void update(uint8_t* buffer, int x, int y);

extern "C" void clear(uint8_t* buffer);

extern "C" void update_nn(uint8_t* buffer);

