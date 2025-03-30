#define UNICODE
#define _UNICODE
#include <windows.h>
#include "main.hpp"

static bool quit = false;

struct Buffer {
    int width;
    int height;
    uint32_t* pixels;
    BITMAPINFO bitmap_info = {};
    HBITMAP bitmap = 0;
    HDC frame_device_context = 0;
};

LRESULT CALLBACK WindowProcessMessage(HWND, UINT, WPARAM, LPARAM);

struct Buffer draw_buffer;
uint32_t* draw_buffer_pixels = new uint32_t[WINDOW_Y * WINDOW_Y];
struct Buffer mnist_buffer;
uint32_t mnist_buffer_pixels[MNIST_SIZE * MNIST_SIZE];
struct Buffer digits_buffer;
uint32_t digits_buffer_pixels[DIGITS_IMAGE_X * DIGITS_IMAGE_Y];

uint32_t saved_digits_buffer[DIGITS_IMAGE_X * DIGITS_IMAGE_Y] = {};

int dense1_weights[INPUT_SIZE*DENSE1_SIZE] = {};
int dense1_bias[DENSE1_SIZE] = {};
int dense2_weights[DENSE1_SIZE*DENSE2_SIZE] = {};
int dense2_bias[DENSE2_SIZE] = {};

int output_buffer[DENSE2_SIZE] = {};

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PSTR pCmdLine, int nCmdShow) {
    const wchar_t window_class_name[] = L"MNIST-x86";
    static WNDCLASS window_class = { 0 };
    window_class.lpfnWndProc = WindowProcessMessage;
    window_class.hInstance = hInstance;
    window_class.lpszClassName = window_class_name;
    RegisterClass(&window_class);
    
    
    assert(WINDOW_Y % MNIST_SIZE == 0);

    draw_buffer.width = draw_buffer.height = WINDOW_Y;
    draw_buffer.pixels = draw_buffer_pixels;

    mnist_buffer.width = mnist_buffer.height = MNIST_SIZE;
    mnist_buffer.pixels = mnist_buffer_pixels;

    digits_buffer.width = DIGITS_IMAGE_X;
    digits_buffer.height = DIGITS_IMAGE_Y;
    digits_buffer.pixels = digits_buffer_pixels;

    load_digit_image((uint8_t*)digits_buffer_pixels);
    load_digit_image((uint8_t*)saved_digits_buffer);

    // set alpha values to 255
    for (int i = 0; i < WINDOW_Y * WINDOW_Y; i++){
        draw_buffer.pixels[i] = 0xFFFF00FF;
    }
    
    load_weights(dense1_weights, dense1_bias, dense2_weights, dense2_bias);

    draw_buffer.bitmap_info.bmiHeader.biSize = sizeof(draw_buffer.bitmap_info.bmiHeader);
    draw_buffer.bitmap_info.bmiHeader.biWidth = WINDOW_Y;
    draw_buffer.bitmap_info.bmiHeader.biHeight = -WINDOW_Y;
    draw_buffer.bitmap_info.bmiHeader.biPlanes = 1;
    draw_buffer.bitmap_info.bmiHeader.biBitCount = 32;
    draw_buffer.bitmap_info.bmiHeader.biCompression = BI_RGB;
    draw_buffer.frame_device_context = CreateCompatibleDC(0);
    
    draw_buffer.bitmap = CreateDIBSection(NULL, &draw_buffer.bitmap_info, DIB_RGB_COLORS, (void**)&draw_buffer.pixels, 0, 0);
    SelectObject(draw_buffer.frame_device_context, draw_buffer.bitmap);

    RECT window_rect = {0, 0, WINDOW_X, WINDOW_Y};
    AdjustWindowRect(&window_rect, WS_OVERLAPPEDWINDOW & (~(WS_THICKFRAME | WS_MAXIMIZEBOX)), FALSE);

    static HWND window_handle = CreateWindow(
        window_class_name,
        L"Drawing Pixels",
        (WS_OVERLAPPEDWINDOW | WS_VISIBLE) & (~(WS_THICKFRAME | WS_MAXIMIZEBOX)),
        640, 300, window_rect.right - window_rect.left, window_rect.bottom - window_rect.top,
        NULL, NULL, hInstance, NULL
    );

    if(window_handle == NULL)
        return -1;

    while(!quit){
        static MSG message = { 0 };
        while(PeekMessage(&message, NULL, 0, 0, PM_REMOVE)) { DispatchMessage(&message); }
        
        InvalidateRect(window_handle, NULL, FALSE);
        UpdateWindow(window_handle);
    }
    return 0;
}

LRESULT CALLBACK WindowProcessMessage(HWND window_handle, UINT message, WPARAM wParam, LPARAM lParam) {
    switch(message) {
        case WM_QUIT:
        case WM_DESTROY:
            delete[] draw_buffer_pixels;
            quit = true;
            break;
        
        case WM_PAINT:
            static PAINTSTRUCT paint;
            static HDC device_context;
            device_context = BeginPaint(window_handle, &paint);

            BitBlt(device_context, 0, 0, WINDOW_Y, WINDOW_Y, draw_buffer.frame_device_context, 0, 0, SRCCOPY);

            EndPaint(window_handle, &paint);
            break;
        default:
            return DefWindowProc(window_handle, message, wParam, lParam);
    }
    return 0;
}

// if (sf::Mouse::isButtonPressed(sf::Mouse::Button::Left)){
//     update_on_mouse_click(buffer, sf::Mouse::getPosition(window).x, sf::Mouse::getPosition(window).y);
//     texture.update(buffer);
//     sprite.setTexture(texture);
    
//     get_draw_region_features(buffer, mnist_buffer);
// }

// if (sf::Mouse::isButtonPressed(sf::Mouse::Button::Right)){
//     clear_draw_region(buffer);
    
//     texture.update(buffer);
//     sprite.setTexture(texture);
    
//     get_draw_region_features(buffer, mnist_buffer);
// }

// if (sf::Keyboard::isKeyPressed(sf::Keyboard::Key::Space)){
//     run_network(mnist_buffer, dense1_weights, dense1_bias, dense2_weights, dense2_bias, output_buffer);
    
//     int max = -10000000;
//     int val = 0;
//     for (int i = 0; i < DENSE2_SIZE; i++){
//         if (output_buffer[i]/256 > max){
//             max = output_buffer[i]/256;
//             val = i;
//         }
//     }
    
//     std::cout << "number is: " << val << std::endl;
    
//     for (int i = 0; i < DIGITS_IMAGE_X*DIGITS_IMAGE_Y*4; i++){
//         digits_buffer[i] = saved_digits_buffer[i];
//     }
    
//     draw_circle_on_digits(digits_buffer, 25, 24 + val*DIGITS_IMAGE_Y/10, 20);
//     digits_texture.update(digits_buffer);
//     digits_sprite.setTexture(digits_texture);
// }

// window.clear();
// window.draw(sprite);
// window.draw(digits_sprite);
// window.display();
// }