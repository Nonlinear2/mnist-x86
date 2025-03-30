#define UNICODE
#define _UNICODE
#include <windows.h>
#include "main.hpp"

static bool quit = false;

typedef struct {
    int width;
    int height;
    uint32_t* pixels;
    BITMAPINFO bitmap_info;
    HBITMAP bitmap = 0;
} Buffer;

LRESULT CALLBACK WindowProcessMessage(HWND, UINT, WPARAM, LPARAM);

static HDC frame_device_context = 0;

Buffer draw_buffer;
Buffer mnist_buffer;
Buffer digits_buffer;

uint8_t digits_buffer[digits_image_x*digits_image_y*4] = {};

uint8_t saved_digits_buffer[digits_image_x*digits_image_y*4] = {};

int dense1_weights[input_size*dense1_size] = {};
int dense1_bias[dense1_size] = {};
int dense2_weights[dense1_size*dense2_size] = {};
int dense2_bias[dense2_size] = {};

int output_buffer[dense2_size] = {};

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PSTR pCmdLine, int nCmdShow) {
    const wchar_t window_class_name[] = L"MNIST-x86";
    static WNDCLASS window_class = { 0 };
    window_class.lpfnWndProc = WindowProcessMessage;
    window_class.hInstance = hInstance;
    window_class.lpszClassName = window_class_name;
    RegisterClass(&window_class);
    
    draw_buffer.bitmap_info.bmiHeader.biSize = sizeof(draw_buffer.bitmap_info.bmiHeader);
    draw_buffer.bitmap_info.bmiHeader.biPlanes = 1;
    draw_buffer.bitmap_info.bmiHeader.biBitCount = 32;
    draw_buffer.bitmap_info.bmiHeader.biCompression = BI_RGB;
    frame_device_context = CreateCompatibleDC(0);
    
    draw_buffer.bitmap = CreateDIBSection(NULL, &draw_buffer.bitmap_info, DIB_RGB_COLORS, (void**)&draw_buffer.pixels, 0, 0);
    SelectObject(frame_device_context, draw_buffer.bitmap);

    assert(window_y % mnist_size == 0);

    draw_buffer.width = draw_buffer.height = window_y;
    draw_buffer.pixels = new uint32_t[window_y * window_y];

    uint32_t mnist_buffer_pixels[mnist_size * mnist_size];
    mnist_buffer = {mnist_size, mnist_size, mnist_buffer_pixels};

    uint32_t digits_buffer_pixels[mnist_size * mnist_size];
    digits_buffer = {digits_image_x, digits_image_y, digits_buffer_pixels};

    load_digit_image((uint8_t*)digits_buffer_pixels);
    load_digit_image(saved_digits_buffer);

    // set alpha values to 255
    for (int i = 0; i < window_y * window_y; i++){
        draw_buffer.pixels[i] = 0x000000FF;
    }
    
    load_weights(dense1_weights, dense1_bias, dense2_weights, dense2_bias);

    static HWND window_handle = CreateWindow(
        window_class_name,
        L"Drawing Pixels",
        (WS_OVERLAPPEDWINDOW | WS_VISIBLE) & (~WS_THICKFRAME),
        640, 300, 640, 480,
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
            delete[] draw_buffer.pixels;
            quit = true;
            break;
        
        case WM_PAINT:
            static PAINTSTRUCT paint;
            static HDC device_context;
            device_context = BeginPaint(window_handle, &paint);
            BitBlt(device_context,
                paint.rcPaint.left, paint.rcPaint.top,
                paint.rcPaint.right - paint.rcPaint.left, paint.rcPaint.bottom - paint.rcPaint.top,
                frame_device_context,
                paint.rcPaint.left, paint.rcPaint.top,
                SRCCOPY);
                EndPaint(window_handle, &paint);
            break;
        default:
            return DefWindowProc(window_handle, message, wParam, lParam);
        return 0;
    }
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
//     for (int i = 0; i < dense2_size; i++){
//         if (output_buffer[i]/256 > max){
//             max = output_buffer[i]/256;
//             val = i;
//         }
//     }
    
//     std::cout << "number is: " << val << std::endl;
    
//     for (int i = 0; i < digits_image_x*digits_image_y*4; i++){
//         digits_buffer[i] = saved_digits_buffer[i];
//     }
    
//     draw_circle_on_digits(digits_buffer, 25, 24 + val*digits_image_y/10, 20);
//     digits_texture.update(digits_buffer);
//     digits_sprite.setTexture(digits_texture);
// }

// window.clear();
// window.draw(sprite);
// window.draw(digits_sprite);
// window.display();
// }