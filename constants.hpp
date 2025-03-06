#pragma once

// window_y must be a multiple of 28
const unsigned int window_x = 650;
const unsigned int window_y = 560;

constexpr int mnist_size = 28;

constexpr int scale = window_y / mnist_size;

constexpr int digits_image_x = 65;
constexpr int digits_image_y = 537;

// network
constexpr int input_size = mnist_size*mnist_size;
constexpr int dense1_size = 128;
constexpr int dense2_size = 10;