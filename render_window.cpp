#include "render_window.hpp"

const unsigned int window_x = 150;
const unsigned int window_y = 150;

int main(){
    sf::RenderWindow window(sf::VideoMode(window_x, window_y), "MNIST x86");
    uint8_t buffer[window_x * window_y * 4] = {};

    // set alpha values to 255
    for (int i = 0; i < window_x * window_y; i++)
        buffer[i*4+3] = 255;

    sf::Texture texture;
    texture.create(window_x, window_y);
    texture.update(buffer);
    sf::Sprite sprite(texture);

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
        }

        if (sf::Mouse::isButtonPressed(sf::Mouse::Right)){
            clear(buffer);
            texture.update(buffer);
            sprite.setTexture(texture);
        }

        window.clear();
        window.draw(sprite);
        window.display();
    }
    return 0;
}