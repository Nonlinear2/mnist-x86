#include "render_window.hpp"

// window size must be a multiple of 28
const unsigned int window_x = 256;
const unsigned int window_y = 168;

void quantize_screen(uint8_t* in_buffer, uint8_t* out_buffer){
    constexpr int scale = 6;
    constexpr int width = 28;
    constexpr int height = 28;

    for (int y = 0; y < height; y++){
        for (int x = 0; x < width; x++){
            int accumulator = 0;
            for (int j = 0; j < scale; j++){
                for (int i = 0; i < scale; i++){
                    int index = ((y * scale + j) * scale * width + (x * scale + i)) * 4;
                    int r = static_cast<int>(in_buffer[index]);
                    // int g = static_cast<int>(in_buffer[index + 1]);
                    // int b = static_cast<int>(in_buffer[index + 2]);
                    accumulator += r; //+ g + b;
                }
            }
            out_buffer[y * width + x] = static_cast<uint8_t>(accumulator / (scale * scale)); // * 3 average rgb to get grayscale
        }
    }
}

void duplicate(uint8_t* in_buffer, uint8_t* out_buffer){
    for (int i = 0; i < 28*28; i++){
        out_buffer[4*i] = in_buffer[i];
        out_buffer[4*i + 1] = in_buffer[i];
        out_buffer[4*i + 2] = in_buffer[i];
        out_buffer[4*i + 3] = 255;
    }
}

void update(uint8_t* buffer, int x, int y){
    x = x / 6 * 6;
    y = y / 6 * 6;
    for (int j = 0; j < 6; j++){
        for (int i = 0; i < 6; i++){
            buffer[((y + j) * 168 + (x + i)) * 4] = 255;
        }
    }
}



void load_weights(int* dense1_weights, int* dense1_bias, int* dense2_weights, int* dense2_bias){
    
    constexpr int input_size = 28*28;
    constexpr int dense1_size = 128;
    constexpr int dense2_size = 10;
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
    
    constexpr int input_size = 28*28;
    constexpr int dense1_size = 128;
    constexpr int dense2_size = 10;
    
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

void load_digit_image(uint8_t* image_buffer, int digit){
    std::string input_path = "./digits_images/" + std::to_string(digit) + ".data";

    constexpr int image_size = 36;
    
    std::ifstream image_stream;
    image_stream.open(input_path, std::ios::binary);
    if (image_stream.is_open())
        image_stream.read(reinterpret_cast<char*>(image_buffer), 
                            image_size*image_size*4*sizeof(uint8_t)); // * 4 is for rgba
    else
        std::cout << "error loading weights \n";

    image_stream.close();
}


int main(){
    assert(window_y % 28 == 0);

    sf::RenderWindow window(sf::VideoMode(window_x, window_y), "MNIST x86");
    uint8_t buffer[window_y * window_y * 4] = {};

    uint8_t mnist_buffer[28*28] = {};
    uint8_t draw_mnist_buffer[28*28*4] = {};

    // image size is 36x36
    uint8_t digit_1[36*36*4] = {};
    load_digit_image(digit_1, 1);

    // set alpha values to 255
    for (int i = 0; i < window_y * window_y; i++){
        buffer[i*4+3] = 255;
    }

    sf::Texture texture;
    texture.create(window_y, window_y);
    texture.update(buffer);
    sf::Sprite sprite(texture);

    sf::Texture mnist_texture;
    mnist_texture.create(28, 28);
    mnist_texture.update(draw_mnist_buffer);
    sf::Sprite mnist_sprite(mnist_texture);

    sf::Texture digit_1_texture;
    digit_1_texture.create(36, 36);
    digit_1_texture.update(digit_1);
    sf::Sprite digit_1_sprite(digit_1_texture);
    digit_1_sprite.setPosition(window_y + 10, 0);

    // network
    constexpr int input_size = 28*28;
    constexpr int dense1_size = 128;
    constexpr int dense2_size = 10;

    int dense1_weights[input_size*dense1_size] = {};
    int dense1_bias[dense1_size] = {};
    int dense2_weights[dense1_size*dense2_size] = {};
    int dense2_bias[dense2_size] = {};

    load_weights(dense1_weights, dense1_bias, dense2_weights, dense2_bias);
    int output_buffer[dense2_size] = {};

    while (window.isOpen()){
        sf::Event event;
        while (window.pollEvent(event)){
            switch (event.type){
                case sf::Event::Closed: 
                    window.close();
                    break;
                default:
                    break;
            }
        }
        if (sf::Mouse::isButtonPressed(sf::Mouse::Left)){
            update(buffer, sf::Mouse::getPosition(window).x, sf::Mouse::getPosition(window).y);
            texture.update(buffer);
            sprite.setTexture(texture);

            quantize_screen(buffer, mnist_buffer);
            duplicate(mnist_buffer, draw_mnist_buffer);
            mnist_texture.update(draw_mnist_buffer);
            mnist_sprite.setTexture(mnist_texture);
        }

        if (sf::Mouse::isButtonPressed(sf::Mouse::Right)){
            clear(buffer);
            texture.update(buffer);
            sprite.setTexture(texture);
        }

        if (sf::Keyboard::isKeyPressed(sf::Keyboard::Space)){
            run_network(mnist_buffer, dense1_weights, dense1_bias, dense2_weights, dense2_bias, output_buffer);
            for (int i = 0; i < dense2_size; i++){
                std::cout << output_buffer[i]/256 << std::endl;
            }

            int max = -10000000;
            int val = 0;
            for (int i = 0; i < dense2_size; i++){
                if (output_buffer[i]/256 > max){
                    max = output_buffer[i]/256;
                    val = i;
                }
            }
            std::cout << "===================\n";
            std::cout << "number is: " << val << std::endl;
            std::cout << "===================\n";
        }

        window.clear();
        window.draw(sprite);
        window.draw(mnist_sprite);
        window.draw(digit_1_sprite);
        window.display();
    }
    return 0;
}