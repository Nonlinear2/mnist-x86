extern CreateWindowExA
extern DefWindowProcA
extern DispatchMessageA
extern ExitProcess
extern GetMessageA
extern GetModuleHandleA
extern IsDialogMessageA
extern LoadImageA
extern PostQuitMessage
extern RegisterClassExA
extern ShowWindow
extern TranslateMessage
extern UpdateWindow

global main

%define WINDOW_X                    650
%define WINDOW_Y                    560
%define MNIST_SIZE                  28
%define DRAW_REGION_SIZE            WINDOW_Y
%define SCALE                       WINDOW_Y / MNIST_SIZE
%define DIGITS_IMAGE_X              50
%define DIGITS_IMAGE_Y              560

%define DRAW_BUFFER_BYTE_SIZE       WINDOW_Y * WINDOW_Y * 4
%define DIGITS_BUFFER_BYTE_SIZE     DIGITS_IMAGE_X * DIGITS_IMAGE_Y * 4
%define MNIST_ARRAY_BYTE_SIZE       MNIST_SIZE * MNIST_SIZE * 4

%define DENSE1_BYTE_SIZE                4*DENSE1_SIZE
%define DENSE2_BYTE_SIZE                4*DENSE2_SIZE

%define DENSE1_WEIGHTS_BYTE_SIZE        INPUT_SIZE*DENSE1_SIZE*4
%define DENSE2_WEIGHTS_BYTE_SIZE        DENSE1_SIZE*DENSE2_SIZE*4

section .data
window_name  dw 'M', 'N', 'I', 'S', 'T', '-', 'x', '8', '6', 0    ; wide character string

quit db 0
lmb_down db 0

align 8
draw_buffer:    
    dq 0                            ; pixels (uint8_t*, 8 bytes, 8 bytes aligned)
    dq 0                            ; bitmap (HBITMAP, 8 bytes, 8 bytes aligned)
    dq 0                            ; frame_device_context (HDC, 8 bytes, 8 bytes aligned)
    dd WINDOW_Y                     ; width (int, 4 bytes, 4 bytes aligned)
    dd WINDOW_Y                     ; height (int, 4 bytes, 4 bytes aligned)
    times 44 db 0                   ; bitmap_info (BITMAPINFO, 44 bytes, 4 bytes aligned)
    times 4 db 0                    ; Padding for alignment    

align 8
digits_buffer:    
    dq 0                            ; pixels (uint8_t*, 8 bytes, 8 bytes aligned)
    dq 0                            ; bitmap (HBITMAP, 8 bytes, 8 bytes aligned)
    dq 0                            ; frame_device_context (HDC, 8 bytes, 8 bytes aligned)
    dd DIGITS_IMAGE_X               ; width (int, 4 bytes, 4 bytes aligned)
    dd DIGITS_IMAGE_Y               ; height (int, 4 bytes, 4 bytes aligned)
    times 44 db 0                   ; bitmap_info (BITMAPINFO, 44 bytes, 4 bytes aligned)
    times 4 db 0                    ; Padding for alignment

%define draw_buffer.pixels                      draw_buffer + 0
%define draw_buffer.bitmap                      draw_buffer + 8
%define draw_buffer.frame_device_context        draw_buffer + 16
%define draw_buffer.width                       draw_buffer + 20
%define draw_buffer.height                      draw_buffer + 24
%define draw_buffer.bitmap_info                 draw_buffer + 28

%define digits_buffer.pixels                    draw_buffer + 0
%define digits_buffer.bitmap                    draw_buffer + 8
%define digits_buffer.frame_device_context      draw_buffer + 16
%define digits_buffer.width                     draw_buffer + 20
%define digits_buffer.height                    draw_buffer + 24
%define digits_buffer.bitmap_info               draw_buffer + 28

section .bss
align 8
hInstance resq 1

draw_buffer_pixels resb DRAW_BUFFER_BYTE_SIZE
mnist_array resb MNIST_ARRAY_BYTE_SIZE
digits_buffer resb DIGITS_BUFFER_BYTE_SIZE
saved_digits_buffer resb DIGITS_BUFFER_BYTE_SIZE

dense1_weights resb DENSE1_WEIGHTS_BYTE_SIZE
dense1_bias resb DENSE1_BYTE_SIZE
dense2_weights resb DENSE2_WEIGHTS_BYTE_SIZE
dense2_bias resb DENSE2_BYTE_SIZE

output_buffer resb DENSE2_BYTE_SIZE

paint resb 72           ; PAINTSTRUCT (72 bytes)
device_context resb 8   ; HDC (8 bytes)


section .text

main:
    ; Function prologue
    push    rbp
    mov     rbp, rsp
    sub     rsp, 32                                 ; Reserve 32 bytes of shadow space
    
    xor rcx, rcx
    call GetModuleHandleA
    mov [rel hInstance], rax

    call WinMain

    ; Function epilogue
    xor rax, rax                  ; Return 0

    mov rsp, rbp ; Deallocate local variables
    pop rbp ; Restore the caller's base pointer value
    ret

; int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PSTR pCmdLine, int nCmdShow);
WinMain:
    ; Function prologue
    push    rbp
    mov     rbp, rsp
    sub     rsp, 32 + ...                                 ; Reserve 32 bytes of shadow space + ... bytes for local variables

    %define window_class                        [rbp - 8]

