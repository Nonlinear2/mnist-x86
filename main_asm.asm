extern RegisterClassW
extern CreateWindowW
extern AdjustWindowRect
extern WindowProcessMessage
extern LoadCursorW

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
digits_buffer_pixels resb DIGITS_BUFFER_BYTE_SIZE
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

; void initialize_device_context(Buffer& buffer, int width, int height);
initialize_device_context:
    ; Function prologue
    push    rbp
    mov     rbp, rsp
    sub     rsp, 32                                 ; Reserve 32 bytes of shadow space

    ; buffer in rcx
    ; width in rdx
    ; height in r8

    ; buffer.bitmap_info.bmiHeader.biSize = sizeof(buffer.bitmap_info.bmiHeader);
    ; buffer.bitmap_info.bmiHeader.biWidth = width;
    ; buffer.bitmap_info.bmiHeader.biHeight = -height;
    ; buffer.bitmap_info.bmiHeader.biPlanes = 1;
    ; buffer.bitmap_info.bmiHeader.biBitCount = 32;
    ; buffer.bitmap_info.bmiHeader.biCompression = BI_RGB;
    ; buffer.frame_device_context = CreateCompatibleDC(0);
    
    ; buffer.bitmap = CreateDIBSection(NULL, &buffer.bitmap_info, DIB_RGB_COLORS, (void**)&buffer.pixels, 0, 0);
    ; SelectObject(buffer.frame_device_context, buffer.bitmap);
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
        
    ; hInstance in rcx
    ; hPrevInstance in rdx
    ; pCmdLine in r8
    ; nCmdShow in r9

    %define window_class                        rbp - 72    ; WNDCLASS structure, 72 bytes

    %define window_class.style                  rbp - 72    ; UINT, 4 bytes + 4 padding bytes
    %define window_class.lpfnWndProc            rbp - 64    ; WNDPROC, 8 bytes
    %define window_class.cbClsExtra             rbp - 56    ; int, 4 bytes
    %define window_class.cbWndExtra             rbp - 52    ; int, 4 bytes
    %define window_class.hInstance              rbp - 48    ; HINSTANCE, 8 bytes
    %define window_class.hIcon                  rbp - 40    ; HICON, 8 bytes
    %define window_class.hCursor                rbp - 32    ; HCURSOR, 8 bytes
    %define window_class.hbrBackground          rbp - 24    ; HBRUSH, 8 bytes
    %define window_class.lpszMenuName           rbp - 16    ; LPCWSTR, 8 bytes
    %define window_class.lpszClassName          rbp - 8     ; LPCWSTR, 8 bytes

    %define hInstance                           rbp - 80    ; HINSTANCE, 8 bytes
    mov [hInstance], rcx

    mov [window_class.lpfnWndProc], WindowProcessMessage
    mov [window_class.hInstance], [hInstance]
    
    lea rax, [rel window_name]
    mov [window_class.lpszClassName], rax

    ; window_class.hbrBackground = (HBRUSH)GetStockObject(BLACK_BRUSH);
    mov rcx, BLACK_BRUSH
    call GetStockObject
    mov [window_class.hbrBackground], rax

    lea rcx, [window_class]
    call RegisterClassW


    mov DWORD [draw_buffer.width], DWORD WINDOW_Y
    mov DWORD [draw_buffer.height], DWORD WINDOW_Y
    
    lea QWORD [draw_buffer.pixels], [rel draw_buffer_pixels]

    mov DWORD [digits_buffer.width], DWORD DIGITS_IMAGE_X
    mov DWORD [digits_buffer.height], DWORD DIGITS_IMAGE_Y
    
    lea QWORD [draw_buffer.pixels], [rel digits_buffer_pixels]

    lea rcx, [rel dense1_weights]
    lea rdx, [rel dense1_bias]
    lea r8, [rel dense2_weights]
    lea r9, [rel dense2_bias]
    call load_weights

    
    lea rcx, [rel draw_buffer]
    mov QWORD rdx, QWORD WINDOW_X
    mov QWORD r8, QWORD WINDOW_Y
    call initialize_device_context

    lea rcx, [rel digits_buffer]
    mov QWORD rdx, QWORD DIGITS_IMAGE_X
    mov QWORD r8, QWORD DIGITS_IMAGE_Y
    call initialize_device_context

    mov rcx, [digits_buffer.pixels]
    call load_digit_image

    lea rcx, [rel saved_digits_buffer]
    call load_digit_image

    %define window_rect                     window_class - 32
    %define window_rect.left                window_class - 32
    %define window_rect.top                 window_class - 24
    %define window_rect.right               window_class - 16
    %define window_rect.bottom              window_class - 8

    mov QWORD [window_rect.left], QWORD 0
    mov QWORD [window_rect.top], QWORD 0
    mov QWORD [window_rect.right], QWORD WINDOW_X
    mov QWORD [window_rect.bottom], QWORD WINDOW_Y

    %define val WS_OVERLAPPEDWINDOW & (~(WS_THICKFRAME | WS_MAXIMIZEBOX))
    mov rcx, window_rect
    mov rdx, val
    xor r8, r8
    call AdjustWindowRect

    %define val (WS_OVERLAPPEDWINDOW | WS_VISIBLE) & (~(WS_THICKFRAME | WS_MAXIMIZEBOX)),
    lea rcx, [rel window_name]
    lea rdx, [rel window_name]
    mov r8, val
    mov r9, 440
    push NULL
    push hInstance
    push NULL
    push NULL
    mov rax [window_rect.bottom]
    sub rax, [window_rect.top]
    push rax
    mov rax [window_rect.right]
    sub rax, [window_rect.left]
    push rax
    push 120
    call CreateWindowW

    %define window_handle                       window_rect - 8
    mov window_handle rax

    cmp rax, NULL
    je .crash

    mov rcx, NULL
    mov rdx, IDC_ARROW

    call LoadCursorW
    mov rcx, rax

    call SetCursor

    %define message                         window_handle - 8 
    .mainloop:
    mov QWORD [message], QWORD 0

    .while:
    mov rcx, message
    mov rdx, NULL
    mov r8, 0
    mov r9, 0
    push PM_REMOVE
    call PeekMessage

    cmp rax, 0
    je .break_while

    mov rcx, message
    call DispatchMessage
    jmp .while
    .break_while:

    mov rcx, window_handle
    mov rdx, NULL
    mov r8, FALSE
    call InvalidateRect

    mov rcx, window_handle
    call UpdateWindowW

    cmp quit, 0
    je .return
    jmp .mainloop

    .return:
        ; Function epilogue
    xor rax, rax                  ; Return 0
    .crash:
    mov rsp, rbp ; Deallocate local variables
    pop rbp ; Restore the caller's base pointer value
    ret

WindowProcessMessage:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 32                                 ; Reserve 32 bytes of shadow space + ... bytes for local variables
    
    push r9
    push r8
    push rdx
    push rcx

    %define window_handle                           rbp - 32
    %define message                                 rbp - 24
    %define wParam                                  rbp - 16
    %define lParam                                  rbp - 8

    ; switch
    cmp [message], WM_QUIT
    je .destroy

    cmp [message], WM_DESTROY
    je .destroy

    cmp [message], WM_LBUTTONDOWN
    je .lmb_down

    cmp [message], WM_MOUSEMOVE
    je .mouse_move

    cmp [message], WM_LBUTTONUP
    je .lmb_up

    cmp [message], WM_RBUTTONDOWN
    je .rmb_down

    cmp [message], WM_KEYDOWN
    je .key_down

    cmp [message], WM_CAPTURECHANGED
    je .capture_changed

    cmp [message], WM_PAINT
    je .paint

    mov rcx, [window_handle]
    mov rdx, [message]
    mov r8, [wParam]
    mov r9, [lParam]
    call DefWindowProc

    jmp .break

    .destroy:
    mov [quit], 1
    jmp .break

    .lmb_down:
    mov [lmb_down], 1
    mov rcx, [window_handle]
    call SetCapture

    .mouse_move:
    cmp lmb_down, 0
    je .break
    mov rcx, [draw_buffer.pixels]
    mov rdx, [lParam]
    and rdx, 0x00000000ffffffff
    mov r8, [lParam]
    shr r8, 0xffffffff
    call update_on_mouse_click

    mov rcx, [draw_buffer.pixels]
    mov rdx, [mnist_array]
    call get_draw_region_features

    mov rcx, window_handle
    mov rdx, NULL
    mov r8, FALSE
    call InvalidateRect
    jmp .break

    .lmb_up:
    mov [lmb_down], 0
    call ReleaseCapture
    jmp .break

    .rmb_down:
    mov rcx, draw_buffer.pixels
    call clear_draw_region
    jmp .break

    .key_down:
    cmp [wParam], VK_SPACE
    jne .break
    mov
    jmp .break

    .capture_changed:
    mov [lmb_down], 0
    jmp .break

    .paint:
    

    .break:
    ; Function epilogue
    xor rax, rax                  ; Return 0
    
    mov rsp, rbp ; Deallocate local variables
    pop rbp ; Restore the caller's base pointer value
    ret