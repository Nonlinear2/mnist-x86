#include "render_window.hpp"

void clear_draw_region(uint8_t* buffer){
    for (int y; y < window_y; y++){
        for (int x; x < window_y; x++){
            buffer[window_y*y + x] = 0;
            buffer[window_y*y + x + 1] = 0;
            buffer[window_y*y + x + 2] = 0;
        }
    }
}

void quantize_screen(uint8_t* in_buffer, uint8_t* out_buffer){

    for (int y = 0; y < mnist_size; y++){ // height
        for (int x = 0; x < mnist_size; x++){ // width
            int accumulator = 0;
            for (int j = 0; j < scale; j++){
                for (int i = 0; i < scale; i++){
                    int index = ((y * scale + j) * scale * mnist_size + (x * scale + i)) * 4; // width
                    int r = static_cast<int>(in_buffer[index]);
                    // int g = static_cast<int>(in_buffer[index + 1]);
                    // int b = static_cast<int>(in_buffer[index + 2]);
                    accumulator += r; //+ g + b;
                }
            }
            // * 3 average rgb to get grayscale
            out_buffer[y * mnist_size + x] = static_cast<uint8_t>(accumulator / (scale * scale)); // width
        }
    }
}

void duplicate(uint8_t* in_buffer, uint8_t* out_buffer){
    for (int i = 0; i < mnist_size*mnist_size; i++){
        out_buffer[4*i] = in_buffer[i];
        out_buffer[4*i + 1] = in_buffer[i];
        out_buffer[4*i + 2] = in_buffer[i];
        out_buffer[4*i + 3] = 255;
    }
}

void update_quantized_pixel(uint8_t* buffer, int x, int y){
    if (x < 0 || y < 0 || x >= window_y || y >= window_y)
        return;

    for (int j = 0; j < scale; j++){
        for (int i = 0; i < scale; i++){
            buffer[((y + j) * window_y + (x + i)) * 4] = 255;
        }
    }
}

void update(uint8_t* buffer, int x, int y){

    x = x / scale * scale;
    y = y / scale * scale;

    update_quantized_pixel(buffer, x, y);

    update_quantized_pixel(buffer, x-scale, y);
    update_quantized_pixel(buffer, x+scale, y);

    update_quantized_pixel(buffer, x, y-scale);
    update_quantized_pixel(buffer, x, y+scale);
}

void load_digit_image(uint8_t* image_buffer){
    std::string input_path = "./digits_images/all_digits.data";
    
    std::ifstream image_stream;
    image_stream.open(input_path, std::ios::binary);
    if (image_stream.is_open())
        image_stream.read(reinterpret_cast<char*>(image_buffer), 
                            digits_image_x*digits_image_y*4*sizeof(uint8_t)); // * 4 is for rgba
    else
        std::cout << "error loading weights \n";

    image_stream.close();
}

void draw_circle(uint8_t* buffer, int x, int y, int r){
    // midpoint circle algorithm
    int x_ = x;
    int y_ = y - r;
    int p = -r;

    while (x_ < -y_){
        if (p > 0){
            y_ += 1;
            p += 2*(x_ + y_) + 1;
        } else {
            p += 2*x + 1;
        }
    }
}