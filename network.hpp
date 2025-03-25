#include <iostream>
#include <cstdint>
#include <cassert>
#include <fstream>
#include "constants.hpp"

// void load_weights(int* dense1_weights, int* dense1_bias, int* dense2_weights, int* dense2_bias);

extern "C" void load_weights(int* dense1_weights, int* dense1_bias, int* dense2_weights, int* dense2_bias);

// void run_network(uint8_t* input_buffer,
//                  int* dense1_weights, int* dense1_bias, int* dense2_weights, int* dense2_bias,
//                  int* output_buffer);

extern "C" void run_network(uint8_t* input_buffer,
                            int* dense1_weights, int* dense1_bias, int* dense2_weights, int* dense2_bias,
                            int* output_buffer);