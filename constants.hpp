#pragma once

// window_y must be a multiple of 28
const unsigned int window_x = 650;
const unsigned int window_y = 560;

const unsigned int draw_region_size = window_y;

constexpr int mnist_size = 28;

constexpr int scale = draw_region_size / mnist_size;

constexpr int digits_image_x = 50;
constexpr int digits_image_y = 560;

// network
constexpr int input_size = mnist_size*mnist_size;
constexpr int dense1_size = 128;
constexpr int dense2_size = 10;