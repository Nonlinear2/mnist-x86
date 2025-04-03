extern WindowProcessMessage
extern GetModuleHandleW
extern GetStockObject
extern RegisterClassW
extern AdjustWindowRect
extern CreateWindowExW
extern LoadCursorW
extern SetCursor
extern PeekMessageW
extern DispatchMessageW
extern InvalidateRect
extern DefWindowProcW
extern SetCapture
extern BeginPaint
extern BitBlt
extern EndPaint

extern UpdateWindow
extern ReleaseCapture

extern MakeIntResourceW

extern load_weights
extern load_digit_image
extern clear_draw_region
extern draw_circle_on_digits
extern get_draw_region_features
extern update_on_mouse_click
extern run_network


global main

%define WINDOW_X                    650
%define WINDOW_Y                    560
%define MNIST_SIZE                  28
%define DRAW_REGION_SIZE            WINDOW_Y
%define SCALE                       WINDOW_Y / MNIST_SIZE
%define DIGITS_IMAGE_X              50
%define DIGITS_IMAGE_Y              560
%define DIGITS_IMAGE_BYTE_SIZE      DIGITS_IMAGE_X*DIGITS_IMAGE_Y*4

%define DRAW_BUFFER_BYTE_SIZE       WINDOW_Y * WINDOW_Y * 4
%define DIGITS_BUFFER_BYTE_SIZE     DIGITS_IMAGE_X * DIGITS_IMAGE_Y * 4
%define MNIST_ARRAY_BYTE_SIZE       MNIST_SIZE * MNIST_SIZE * 4

%define MNIST_SIZE                      28
%define INPUT_SIZE                      MNIST_SIZE*MNIST_SIZE

%define DENSE1_SIZE                     128
%define DENSE2_SIZE                     10

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
    call GetModuleHandleW
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
    sub     rsp, 32 + 120                                 ; Reserve 32 bytes of shadow space + ... bytes for local variables
        
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

    mov QWORD [window_class.lpfnWndProc], QWORD WindowProcessMessage
    mov [window_class.hInstance], rcx
    
    lea rax, [rel window_name]
    mov [window_class.lpszClassName], rax

    ; window_class.hbrBackground = (HBRUSH)GetStockObject(BLACK_BRUSH);
    mov rcx, QWORD 4                   ; BLACK_BRUSH
    call GetStockObject
    mov [window_class.hbrBackground], rax

    lea rcx, [window_class]
    call RegisterClassW


    mov DWORD [draw_buffer.width], DWORD WINDOW_Y
    mov DWORD [draw_buffer.height], DWORD WINDOW_Y
    
    lea rax, QWORD [rel draw_buffer_pixels]
    mov QWORD [draw_buffer.pixels], rax

    mov DWORD [digits_buffer.width], DWORD DIGITS_IMAGE_X
    mov DWORD [digits_buffer.height], DWORD DIGITS_IMAGE_Y
    
    lea rax, QWORD [rel digits_buffer_pixels]
    mov QWORD [draw_buffer.pixels], rax

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

    lea rcx, [window_rect]
    mov rdx, 0xCA0000                       ; WS_OVERLAPPEDWINDOW & (~(WS_THICKFRAME | WS_MAXIMIZEBOX))
    xor r8, r8
    call AdjustWindowRect

    xor rcx, rcx                            ; dwExStyle = 0 
    lea rdx, [rel window_name]
    lea r8, [rel window_name]
    mov r9, 0x10CA0000                      ; (WS_OVERLAPPEDWINDOW | WS_VISIBLE) & (~(WS_THICKFRAME | WS_MAXIMIZEBOX))
    push QWORD 440
    push QWORD 0                                  ; NULL
    lea rax, [hInstance]
    push rax
    push QWORD 0                                  ; NULL
    push QWORD 0                                  ; NULL
    mov rax, [window_rect.bottom]
    sub rax, [window_rect.top]
    push rax
    mov rax, [window_rect.right]
    sub rax, [window_rect.left]
    push rax
    push 120
    call CreateWindowExW

    add rsi, 56

    %define window_handle                       window_rect - 8
    mov [window_handle], rax

    cmp rax, 0                              ; NULL
    je .crash

    mov rcx, 0                              ; NULL
    mov rdx, 32512                          ; IDC_ARROW

    call LoadCursorW
    mov rcx, rax

    call SetCursor

    %define message                         window_handle - 8 
    .mainloop:
    mov QWORD [message], QWORD 0

    .while:
    lea rcx, [message]
    mov rdx, 0                              ; NULL
    mov r8, 0
    mov r9, 0
    push 0x0001                             ; PM_REMOVE
    call PeekMessageW

    add rsi, 8

    cmp rax, 0
    je .break_while

    lea rcx, [message]
    call DispatchMessageW
    jmp .while
    .break_while:

    lea rcx, [window_handle]
    mov rdx, 0                          ; NULL
    mov r8, 0                           ; FALSE
    call InvalidateRect

    lea rcx, [window_handle]
    call UpdateWindow

    cmp [quit], BYTE 0
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
    cmp QWORD [message], QWORD 0x0012               ; WM_QUIT
    je .destroy

    cmp QWORD [message], QWORD 0x0002               ; WM_DESTROY
    je .destroy

    cmp QWORD [message], QWORD 0x0201               ; WM_LBUTTONDOWN
    je .lmb_down

    cmp QWORD [message], QWORD 0x0200               ; WM_MOUSEMOVE
    je .mouse_move

    cmp QWORD [message], QWORD 0x0202               ; WM_LBUTTONUP
    je .lmb_up

    cmp QWORD [message], QWORD 0x0204               ; WM_RBUTTONDOWN
    je .rmb_down

    cmp QWORD [message], QWORD 0x0100               ; WM_KEYDOWN
    je .key_down

    cmp QWORD [message], QWORD 0x0215               ; WM_CAPTURECHANGED
    je .capture_changed

    cmp QWORD [message], QWORD 0x000F               ; WM_PAINT
    je .paint

    mov rcx, [window_handle]
    mov rdx, [message]
    mov r8, [wParam]
    mov r9, [lParam]
    call DefWindowProcW

    jmp .break

    .destroy:
    mov BYTE [quit], BYTE 1
    jmp .break

    .lmb_down:
    mov BYTE [lmb_down], BYTE 1
    mov rcx, [window_handle]
    call SetCapture

    .mouse_move:
    cmp BYTE [lmb_down], BYTE 0
    je .break
    mov rcx, [draw_buffer.pixels]
    mov rdx, [lParam]
    and rdx, 0x0000ffff
    mov r8, [lParam]
    shr r8, 16
    call update_on_mouse_click

    mov rcx, [draw_buffer.pixels]
    mov rdx, [mnist_array]
    call get_draw_region_features

    lea rcx, [window_handle]
    mov rdx, 0              ; NULL
    mov r8, 0               ; FALSE
    call InvalidateRect
    jmp .break

    .lmb_up:
    mov BYTE [lmb_down], BYTE 0
    call ReleaseCapture
    jmp .break

    .rmb_down:
    lea rcx, draw_buffer.pixels
    call clear_draw_region
    jmp .break

    .key_down:
    cmp QWORD [wParam], QWORD 0x20          ; VK_SPACE
    jne .break

    xor rax, rax
    .loop:
    mov rcx, [saved_digits_buffer + rax]
    mov [digits_buffer_pixels + rax], rcx
    inc rax
    cmp rax, DIGITS_IMAGE_BYTE_SIZE
    jle .loop

    lea rcx, [mnist_array]
    lea rdx, [dense1_weights]
    lea r8, [dense1_bias]
    lea r9, [dense2_weights]
    lea rax, [dense2_bias]
    push rax
    lea rax, [output_buffer]
    push rax
    call run_network

    mov rcx, [output_buffer]
    xor r8, r8
    mov rax, 1
    .loop2:
    cmp rcx, [output_buffer + rax]
    jle .keep
    mov rcx, [output_buffer + rax]
    mov r8, rax
    .keep:

    inc rax
    cmp rax, DENSE2_SIZE
    jle .loop2

    lea rcx, [digits_buffer_pixels]
    mov rdx, 24
    imul r8, 57
    add r8, 24
    mov r9, 20

    call draw_circle_on_digits

    lea rcx, [window_handle] 
    xor rdx, rdx                                ; NULL 
    xor r8, r8                                  ; FALSE
    call InvalidateRect

    jmp .break

    .capture_changed:
    mov BYTE [lmb_down], BYTE 0
    jmp .break

    .paint:
    lea rcx, [window_handle]
    lea rdx, [paint]
    call BeginPaint
    push rax
    mov rcx, rax
    xor rdx, rdx
    xor r8, r8
    mov r9, WINDOW_Y

    push 0x00CC0020                                 ; SRCCOPY
    push QWORD 0
    push QWORD 0
    push draw_buffer.frame_device_context
    push WINDOW_Y

    call BitBlt

    mov QWORD [rsi + 8], QWORD DIGITS_IMAGE_Y

    mov rcx, [rsi + 40]         ; saved rax
    mov rdx, WINDOW_Y + 10
    xor r8, r8
    mov r9, DIGITS_IMAGE_X

    call BitBlt

    add rsi, 48

    lea rcx, [window_handle]
    lea rdx, [paint]
    call EndPaint
    jmp .break

    .break:
    ; Function epilogue
    xor rax, rax                  ; Return 0
    
    mov rsp, rbp ; Deallocate local variables
    pop rbp ; Restore the caller's base pointer value
    ret