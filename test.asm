global WindowProcessMessage

extern GetModuleHandleW
extern CreateCompatibleDC
extern CreateDIBSection
extern SelectObject
extern GetStockObject
extern RegisterClassW
extern AdjustWindowRect
extern CreateWindowExW
extern LoadCursorW
extern SetCursor
extern PeekMessageW
extern WindowProcessMessage
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


extern quit
extern lmb_down
extern draw_buffer
extern digits_buffer
extern mnist_array
extern saved_digits_buffer
extern digits_buffer_pixels
extern dense1_weights
extern dense1_bias
extern dense2_weights
extern dense2_bias
extern output_buffer
extern paint

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


%define draw_buffer.pixels                      draw_buffer + 0
%define draw_buffer.bitmap                      draw_buffer + 8
%define draw_buffer.frame_device_context        draw_buffer + 16
%define draw_buffer.width                       draw_buffer + 20
%define draw_buffer.height                      draw_buffer + 24
%define draw_buffer.bitmap_info                 draw_buffer + 28

%define digits_buffer.pixels                    digits_buffer + 0
%define digits_buffer.bitmap                    digits_buffer + 8
%define digits_buffer.frame_device_context      digits_buffer + 16
%define digits_buffer.width                     digits_buffer + 20
%define digits_buffer.height                    digits_buffer + 24
%define digits_buffer.bitmap_info               digits_buffer + 28

section .text
WindowProcessMessage:
    push    rbp
    mov     rbp, rsp
    ; Reserve 32 bytes of shadow space + 8 bytes for local variables + 8 bytes for 16 byte alignement
    sub     rsp, 48                               

    ; use shadow space, 
    %define window_handle                           rbp + 2*8           ; rcx home
    %define message                                 rbp + 3*8           ; rdx home
    %define wParam                                  rbp + 4*8           ; r8 home
    %define lParam                                  rbp + 5*8           ; r9 home

    mov QWORD [window_handle], rcx
    mov QWORD [message], rdx
    mov QWORD [wParam], r8
    mov QWORD [lParam], r9

    ; switch
    cmp QWORD [message], 0x0012               ; WM_QUIT
    je .destroy

    cmp QWORD [message], 0x0002               ; WM_DESTROY
    je .destroy

    cmp QWORD [message], 0x0201               ; WM_LBUTTONDOWN
    je .lmb_down

    cmp QWORD [message], 0x0200               ; WM_MOUSEMOVE
    je .mouse_move

    cmp QWORD [message], 0x0202               ; WM_LBUTTONUP
    je .lmb_up

    cmp QWORD [message], 0x0204               ; WM_RBUTTONDOWN
    je .rmb_down

    cmp QWORD [message], 0x0100               ; WM_KEYDOWN
    je .key_down

    cmp QWORD [message], 0x0215               ; WM_CAPTURECHANGED
    je .capture_changed

    cmp QWORD [message], 0x000F               ; WM_PAINT
    je .paint

    ; mov rcx, [window_handle]
    ; mov rdx, [message]
    ; mov r8, [wParam]
    ; mov r9, [lParam]
    call DefWindowProcW
    jmp .return

    .destroy:
    mov BYTE [rel quit], 1
    jmp .break

    .lmb_down:
    mov BYTE [rel lmb_down], 1
    mov rcx, [window_handle]
    call SetCapture

    .mouse_move:
    cmp BYTE [rel lmb_down], 0
    je .break
    mov rcx, [rel draw_buffer.pixels]
    mov rdx, [lParam]
    and rdx, 0xffff
    mov r8, [lParam]
    shr r8, 16
    and r8, 0xffff
    call update_on_mouse_click

    mov rcx, [rel draw_buffer.pixels]
    lea rdx, [rel mnist_array]
    call get_draw_region_features

    mov rcx, [window_handle]
    xor rdx, rdx              ; NULL
    xor r8, r8                ; FALSE
    call InvalidateRect
    jmp .break

    .lmb_up:
    mov BYTE [rel lmb_down], 0
    call ReleaseCapture
    jmp .break

    .rmb_down:
    mov rcx, [rel draw_buffer.pixels]
    call clear_draw_region
    jmp .break

    .key_down:
    ; cmp QWORD [wParam], 0x20          ; VK_SPACE
    ; jne .break

    xor rax, rax
    .loop:
    lea rcx, [rel saved_digits_buffer]
    mov rcx, [rcx + rax]

    mov r10, [rel digits_buffer.pixels]
    mov [r10 + rax], rcx

    inc rax
    cmp rax, DIGITS_IMAGE_BYTE_SIZE
    jl .loop

    ; ================
    ; call run_network
    ; ================

    sub rsp, 2 * 8                             ; 2 stack parameters, rsp is still 16 byte aligned
    lea rcx, [rel mnist_array]
    lea rdx, [rel dense1_weights]
    lea r8, [rel dense1_bias]
    lea r9, [rel dense2_weights]
    lea rax, [rel dense2_bias]
    mov QWORD [rsp + 4 * 8], rax
    lea rax, [rel output_buffer]
    mov QWORD [rsp + 5 * 8], rax
    call run_network
    add rsp, 16                                ; clear parameter space

    mov ecx, [rel output_buffer]
    xor r8, r8
    mov rax, 1
    .loop2:
    lea r10, [rel output_buffer]
    mov r10d, [r10 + 4*rax]
    cmp r10d, ecx
    jle .keep
    mov ecx, r10d
    mov r8, rax
    .keep:

    inc rax
    cmp rax, DENSE2_SIZE
    jl .loop2

    mov rcx, [rel digits_buffer.pixels]
    mov rdx, 24
    imul r8, 57
    add r8, 24
    mov r9, 20
    call draw_circle_on_digits

    mov rcx, [window_handle] 
    xor rdx, rdx                                ; NULL 
    xor r8, r8                                  ; FALSE
    call InvalidateRect

    jmp .break

    .capture_changed:
    mov BYTE [rel lmb_down], BYTE 0
    jmp .break

    .paint:
    mov rcx, [window_handle]
    lea rdx, [rel paint]
    call BeginPaint

    %define device_context                          rbp - 8
    mov [device_context], rax

    ; call BitBlt twice

    sub rsp, 6 * 8                                  ; 5 stack parameters + 8 padding bytes, rsp is still 16 byte aligned
    mov rcx, [device_context]
    xor rdx, rdx
    xor r8, r8
    mov r9, WINDOW_Y

    mov QWORD [rsp + 4 * 8], WINDOW_Y
    mov QWORD rax, [draw_buffer.frame_device_context]
    mov QWORD [rsp + 5 * 8], rax
    mov QWORD [rsp + 6 * 8], 0
    mov QWORD [rsp + 7 * 8], 0
    mov QWORD [rsp + 8 * 8], 0x00CC0020             ; SRCCOPY
    call BitBlt

    mov rcx, [device_context]
    mov rdx, WINDOW_Y
    add rdx, 10
    xor r8, r8
    mov r9, DIGITS_IMAGE_X

    mov QWORD [rsp + 4 * 8], DIGITS_IMAGE_Y
    mov QWORD rax, [digits_buffer.frame_device_context]
    mov QWORD [rsp + 5 * 8], rax
    mov QWORD [rsp + 6 * 8], 0
    mov QWORD [rsp + 7 * 8], 0
    mov QWORD [rsp + 8 * 8], 0x00CC0020             ; SRCCOPY
    call BitBlt

    add rsp, 6 * 8                                  ; clear parameter space

    mov rcx, [window_handle]
    lea rdx, [rel paint]
    call EndPaint
    jmp .break

    .break:
    ; Function epilogue
    xor rax, rax                  ; Return 0
    .return:
    mov rsp, rbp ; Deallocate local variables
    pop rbp ; Restore the caller's base pointer value
    ret