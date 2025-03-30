#pragma once

// WINDOW_Y must be a multiple of 28
const unsigned int WINDOW_X = 650;
const unsigned int WINDOW_Y = 560;

const unsigned int DRAW_REGION_SIZE = WINDOW_Y;

constexpr int MNIST_SIZE = 28;

constexpr int SCALE = DRAW_REGION_SIZE / MNIST_SIZE;

constexpr int DIGITS_IMAGE_X = 50;
constexpr int DIGITS_IMAGE_Y = 560;

// network
constexpr int INPUT_SIZE = MNIST_SIZE*MNIST_SIZE;
constexpr int DENSE1_SIZE = 128;
constexpr int DENSE2_SIZE = 10;