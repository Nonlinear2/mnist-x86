#include "main.hpp"

int main(){
    assert(window_y % mnist_size == 0);

    sf::RenderWindow window(sf::VideoMode(window_x, window_y), "MNIST x86");
    uint8_t buffer[window_y * window_y * 4] = {};

    uint8_t mnist_buffer[mnist_size*mnist_size] = {};

    uint8_t digits_buffer[digits_image_x*digits_image_y*4] = {};
    load_digit_image(digits_buffer);

    uint8_t saved_digits_buffer[digits_image_x*digits_image_y*4] = {};
    load_digit_image(saved_digits_buffer);

    // set alpha values to 255
    for (int i = 0; i < window_y * window_y; i++){
        buffer[i*4+3] = 255;
    }

    sf::Texture texture;
    texture.create(window_y, window_y);
    texture.update(buffer);
    sf::Sprite sprite(texture);

    sf::Texture digits_texture;
    digits_texture.create(digits_image_x, digits_image_y);
    digits_texture.update(digits_buffer);
    sf::Sprite digits_sprite(digits_texture);
    digits_sprite.setPosition(window_y + 10, 0);

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
            update_on_mouse_click(buffer, sf::Mouse::getPosition(window).x, sf::Mouse::getPosition(window).y);
            texture.update(buffer);
            sprite.setTexture(texture);

            get_draw_region_data(buffer, mnist_buffer);
        }

        if (sf::Mouse::isButtonPressed(sf::Mouse::Right)){
            clear_draw_region(buffer);

            texture.update(buffer);
            sprite.setTexture(texture);

            get_draw_region_data(buffer, mnist_buffer);
        }

        if (sf::Keyboard::isKeyPressed(sf::Keyboard::Space)){
            run_network(mnist_buffer, dense1_weights, dense1_bias, dense2_weights, dense2_bias, output_buffer);

            int max = -10000000;
            int val = 0;
            for (int i = 0; i < dense2_size; i++){
                if (output_buffer[i]/256 > max){
                    max = output_buffer[i]/256;
                    val = i;
                }
            }

            std::cout << "number is: " << val << std::endl;

            for (int i = 0; i < digits_image_x*digits_image_y*4; i++){
                digits_buffer[i] = saved_digits_buffer[i];
            }

            draw_circle(digits_buffer, 25, 24 + val*digits_image_y/10, 20);
            digits_texture.update(digits_buffer);
            digits_sprite.setTexture(digits_texture);
        }

        window.clear();
        window.draw(sprite);
        window.draw(digits_sprite);
        window.display();
    }
    return 0;
}