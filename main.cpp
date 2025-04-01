#define UNICODE
#define _UNICODE
#include <windows.h>
#include "main.hpp"

static bool quit = false;
static bool lmb_down = false;       // left mouse button down

// int main(){
//     std::cout << sizeof(HWND) << std::endl;
//     return 0;
// }

struct Buffer {
    int width;
    int height;
    uint8_t* pixels;
    BITMAPINFO bitmap_info = {};
    HBITMAP bitmap = 0;
    HDC frame_device_context = 0;
};

LRESULT CALLBACK WindowProcessMessage(HWND, UINT, WPARAM, LPARAM);

struct Buffer draw_buffer;
uint8_t* draw_buffer_pixels = new uint8_t[WINDOW_Y * WINDOW_Y * 4];

uint8_t mnist_array[MNIST_SIZE * MNIST_SIZE * 4];

struct Buffer digits_buffer;
uint8_t digits_buffer_pixels[DIGITS_IMAGE_X * DIGITS_IMAGE_Y * 4];

uint8_t saved_digits_buffer[DIGITS_IMAGE_X * DIGITS_IMAGE_Y * 4] = {};

int dense1_weights[INPUT_SIZE*DENSE1_SIZE] = {};
int dense1_bias[DENSE1_SIZE] = {};
int dense2_weights[DENSE1_SIZE*DENSE2_SIZE] = {};
int dense2_bias[DENSE2_SIZE] = {};

int output_buffer[DENSE2_SIZE] = {};

PAINTSTRUCT paint;
HDC device_context;

void initialize_device_context(Buffer& buffer, int width, int height){
    buffer.bitmap_info.bmiHeader.biSize = sizeof(buffer.bitmap_info.bmiHeader);
    buffer.bitmap_info.bmiHeader.biWidth = width;
    buffer.bitmap_info.bmiHeader.biHeight = -height;
    buffer.bitmap_info.bmiHeader.biPlanes = 1;
    buffer.bitmap_info.bmiHeader.biBitCount = 32;
    buffer.bitmap_info.bmiHeader.biCompression = BI_RGB;
    buffer.frame_device_context = CreateCompatibleDC(0);
    
    buffer.bitmap = CreateDIBSection(NULL, &buffer.bitmap_info, DIB_RGB_COLORS, (void**)&buffer.pixels, 0, 0);
    SelectObject(buffer.frame_device_context, buffer.bitmap);
}

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PSTR pCmdLine, int nCmdShow) {
    const wchar_t window_class_name[] = L"MNIST-x86";
    WNDCLASS window_class = { 0 };
    window_class.lpfnWndProc = WindowProcessMessage;
    window_class.hInstance = hInstance;
    window_class.lpszClassName = window_class_name;
    window_class.hbrBackground = (HBRUSH)GetStockObject(BLACK_BRUSH);
    RegisterClass(&window_class);
    
    
    assert(WINDOW_Y % MNIST_SIZE == 0);

    draw_buffer.width = draw_buffer.height = WINDOW_Y;
    draw_buffer.pixels = draw_buffer_pixels;

    digits_buffer.width = DIGITS_IMAGE_X;
    digits_buffer.height = DIGITS_IMAGE_Y;
    digits_buffer.pixels = digits_buffer_pixels;

    
    load_weights(dense1_weights, dense1_bias, dense2_weights, dense2_bias);
    
    initialize_device_context(draw_buffer, WINDOW_Y, WINDOW_Y);
    initialize_device_context(digits_buffer, DIGITS_IMAGE_X, DIGITS_IMAGE_Y);
    load_digit_image(digits_buffer.pixels);
    load_digit_image(saved_digits_buffer);

    RECT window_rect = {0, 0, WINDOW_X, WINDOW_Y};
    AdjustWindowRect(&window_rect, WS_OVERLAPPEDWINDOW & (~(WS_THICKFRAME | WS_MAXIMIZEBOX)), FALSE);

    static HWND window_handle = CreateWindow(
        window_class_name,
        L"MNIST-x86",
        (WS_OVERLAPPEDWINDOW | WS_VISIBLE) & (~(WS_THICKFRAME | WS_MAXIMIZEBOX)),
        440, 120, window_rect.right - window_rect.left, window_rect.bottom - window_rect.top,
        NULL, NULL, hInstance, NULL
    );

    if(window_handle == NULL)
        return -1;

    SetCursor(LoadCursor(NULL, IDC_ARROW));


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

        case WM_LBUTTONDOWN:
            lmb_down = true;
            SetCapture(window_handle);
        case WM_MOUSEMOVE:
            if (lmb_down){
                update_on_mouse_click(draw_buffer.pixels, LOWORD(lParam), HIWORD(lParam));
                get_draw_region_features(draw_buffer.pixels, mnist_array);
    
                InvalidateRect(window_handle, NULL, FALSE);
            }
            break;

        case WM_LBUTTONUP:
            lmb_down = false;
            ReleaseCapture();
            break;

        case WM_RBUTTONDOWN:
            clear_draw_region(draw_buffer.pixels);
            get_draw_region_features(draw_buffer.pixels, mnist_array);

            InvalidateRect(window_handle, NULL, FALSE);
            break;

        case WM_KEYDOWN:
            if (wParam == VK_SPACE){
                run_network(mnist_array, dense1_weights, dense1_bias, dense2_weights, dense2_bias, output_buffer);
                
                for (int i = 0; i < DIGITS_IMAGE_X*DIGITS_IMAGE_Y*4; i++){
                    digits_buffer.pixels[i] = saved_digits_buffer[i];
                }

                int max = -10000000;
                int val = 0;
                for (int i = 0; i < DENSE2_SIZE; i++){
                    if (output_buffer[i]/256 > max){
                        max = output_buffer[i]/256;
                        val = i;
                    }
                }

                draw_circle_on_digits(digits_buffer.pixels, 24, 24 + val*57, 20);
                InvalidateRect(window_handle, NULL, FALSE);
            }
            break;
        
        case WM_CAPTURECHANGED:
            lmb_down = false;
            break;

        case WM_PAINT:
            device_context = BeginPaint(window_handle, &paint);

            BitBlt(device_context, 0, 0, WINDOW_Y, WINDOW_Y, draw_buffer.frame_device_context, 0, 0, SRCCOPY);
            BitBlt(device_context, WINDOW_Y + 10, 0, DIGITS_IMAGE_X, DIGITS_IMAGE_Y, digits_buffer.frame_device_context, 0, 0, SRCCOPY);

            EndPaint(window_handle, &paint);
            break;
        default:
            return DefWindowProc(window_handle, message, wParam, lParam);
    }
    return 0;
}