#include "main.hpp"

int main(){
    assert(window_y % mnist_size == 0);

    sf::RenderWindow window(sf::VideoMode(window_x, window_y), "MNIST x86");
    uint8_t buffer[window_y * window_y * 4] = {};

    uint8_t mnist_buffer[mnist_size*mnist_size] = {};
    uint8_t draw_mnist_buffer[mnist_size*mnist_size*4] = {};

    uint8_t digits_buffer[digits_image_x*digits_image_y*4] = {};
    load_digit_image(digits_buffer);

    // set alpha values to 255
    for (int i = 0; i < window_y * window_y; i++){
        buffer[i*4+3] = 255;
    }

    sf::Texture texture;
    texture.create(window_y, window_y);
    texture.update(buffer);
    sf::Sprite sprite(texture);

    sf::Texture mnist_texture;
    mnist_texture.create(mnist_size, mnist_size);
    mnist_texture.update(draw_mnist_buffer);
    sf::Sprite mnist_sprite(mnist_texture);

    // 65x558
    sf::Texture digit_1_texture;
    digit_1_texture.create(digits_image_x, digits_image_y);
    digit_1_texture.update(digits_buffer);
    sf::Sprite digit_1_sprite(digit_1_texture);
    digit_1_sprite.setPosition(window_y + 10, 0);

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
            clear_draw_region(buffer);
            texture.update(buffer);
            sprite.setTexture(texture);

            quantize_screen(buffer, mnist_buffer);
            duplicate(mnist_buffer, draw_mnist_buffer);
            mnist_texture.update(draw_mnist_buffer);
            mnist_sprite.setTexture(mnist_texture);
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