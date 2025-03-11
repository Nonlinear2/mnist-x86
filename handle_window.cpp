#include "handle_window.hpp"

// void draw_pixel(uint8_t* draw_buffer, int x, int y, uint8_t value){
//     draw_buffer[4*(draw_region_size*y + x)] = value;
// }

// void draw_square(uint8_t* draw_buffer, int x, int y){
//     if (x < 0 || x >= draw_region_size || y < 0 || y >= draw_region_size)
//         return;

//     for (int j = 0; j < scale; j++){
//         for (int i = 0; i < scale; i++){
//             draw_buffer[((y + j) * draw_region_size + (x + i)) * 4] = 255;
//         }
//     }
// }

// void clear_draw_region(uint8_t* draw_buffer){
//     for (int y = 0; y < draw_region_size; y++){
//         for (int x = 0; x < draw_region_size; x++){
//             draw_pixel(draw_buffer, x, y, 0);
//         }
//     }
// }

// void get_draw_region_features(uint8_t* draw_buffer, uint8_t* out_buffer){
//     for (int y = 0; y < mnist_size; y++){
//         for (int x = 0; x < mnist_size; x++){
//             out_buffer[y * mnist_size + x] = draw_buffer[(y * scale * draw_region_size + x * scale) * 4];
//         }
//     }
// }

void update_on_mouse_click(uint8_t* draw_buffer, int x, int y){

    x = x / scale * scale;
    y = y / scale * scale;

    draw_square(draw_buffer, x, y);

    draw_square(draw_buffer, x-scale, y);
    draw_square(draw_buffer, x+scale, y);

    draw_square(draw_buffer, x, y-scale);
    draw_square(draw_buffer, x, y+scale);
}

void load_digit_image(uint8_t* digits_buffer){
    std::string input_path = "./digits_images/all_digits.data";
    
    std::ifstream image_stream;
    image_stream.open(input_path, std::ios::binary);
    if (image_stream.is_open())
        image_stream.read(reinterpret_cast<char*>(digits_buffer),
                            digits_image_x*digits_image_y*4*sizeof(uint8_t)); // * 4 is for rgba
    else
        std::cout << "error loading weights \n";

    image_stream.close();
}

// performs bound checks
void draw_pixel_on_digits(uint8_t* digits_buffer, int x, int y, int value){ // red for now
    if (x < 0 || y < 0 || x >= digits_image_x || y >= digits_image_y)
        return;
    
    digits_buffer[4*(digits_image_x*y + x)] = value;
}

void draw_circle_on_digits(uint8_t* digits_buffer, int center_x, int center_y, int r){
    // midpoint circle algorithm
    int x = 0;
    int y = -r;
    int p = -r;

    while (x < -y){
        if (p > 0){
            y += 1;
            p += 2*(x + y) + 1;
        } else {
            p += 2*x + 1;
        }

        draw_pixel_on_digits(digits_buffer, center_x + x, center_y + y, 255);
        draw_pixel_on_digits(digits_buffer, center_x - x, center_y + y, 255);
        draw_pixel_on_digits(digits_buffer, center_x + x, center_y - y, 255);
        draw_pixel_on_digits(digits_buffer, center_x - x, center_y - y, 255);

        draw_pixel_on_digits(digits_buffer, center_x + y, center_y + x, 255);
        draw_pixel_on_digits(digits_buffer, center_x + y, center_y - x, 255);
        draw_pixel_on_digits(digits_buffer, center_x - y, center_y + x, 255);
        draw_pixel_on_digits(digits_buffer, center_x - y, center_y - x, 255);
        x += 1;
    }
}