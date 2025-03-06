#include "network.hpp"

void load_weights(int* dense1_weights, int* dense1_bias, int* dense2_weights, int* dense2_bias){

    std::string input_path = "./mnist_simple_layers";

    std::ifstream weights_stream;

    weights_stream.open(input_path + "/layer_1/weights.bin", std::ios::binary);
    if (weights_stream.is_open()){
        weights_stream.read(reinterpret_cast<char*>(dense1_weights), 
                            input_size*dense1_size*sizeof(int));
    } else {
        std::cout << "error loading weights \n";
    }
    weights_stream.close();

    weights_stream.open(input_path + "/layer_1/bias.bin", std::ios::binary);
    if (weights_stream.is_open()){
        weights_stream.read(reinterpret_cast<char*>(dense1_bias), 
                            dense1_size*sizeof(int));
    } else {
        std::cout << "error loading bias \n";
    }
    weights_stream.close();

    
    weights_stream.open(input_path + "/layer_2/weights.bin", std::ios::binary);
    if (weights_stream.is_open()){
        weights_stream.read(reinterpret_cast<char*>(dense2_weights), 
                            dense1_size*dense2_size*sizeof(int));
    } else {
        std::cout << "error loading weights \n";
    }
    weights_stream.close();

    
    weights_stream.open(input_path + "/layer_2/bias.bin", std::ios::binary);
    if (weights_stream.is_open()){
        weights_stream.read(reinterpret_cast<char*>(dense2_bias), 
                            dense2_size*sizeof(int));
    } else {
        std::cout << "error loading bias \n";
    }
    weights_stream.close();
};

void run_network(uint8_t* input_buffer,
                 int* dense1_weights, int* dense1_bias, int* dense2_weights, int* dense2_bias,
                 int* output_buffer){
    
    int layer1_output[dense1_size];

    // layer 1
    for (int row = 0; row < dense1_size; row++){
        layer1_output[row] = dense1_bias[row]; // add bias
        for (int i = 0; i < input_size; i++){
            layer1_output[row] += dense1_weights[row*input_size + i] * static_cast<int>(input_buffer[i]);
        }
    }

    for (int i = 0; i < dense1_size; i++){
        if (layer1_output[i] <= 0)
            layer1_output[i] = 0;
        else
            layer1_output[i] /= 256;
    }

    // layer 2
    for (int row = 0; row < dense2_size; row++){
        output_buffer[row] = dense2_bias[row]; // add bias
        for (int i = 0; i < dense1_size; i++){
            output_buffer[row] += dense2_weights[row*dense1_size + i] * layer1_output[i]; 
        }
    }
}