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

%define bitmap_info_offset                      28

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

    mov     rcx, [rel hInstance]  ; hInstance
    xor     rdx, rdx              ; hPrevInstance (always NULL)
    xor     r8, r8                ; lpCmdLine (NULL)
    xor     r9, r9                ; nCmdShow (0)
    call    WinMain

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
    ; Reserve 32 bytes of shadow space + 24 bytes for local variables + 8 bytes for 16 byte alignement
    sub     rsp, 64

    ; buffer in rcx
    ; width in rdx
    ; height in r8

    %define buffer                              rbp - 8

    mov QWORD [buffer], rcx

    ; =============================
    ; initialize buffer.bitmap_info
    ; =============================

    add rcx, bitmap_info_offset

    ; buffer.bitmap_info.bmiHeader.biSize = sizeof(buffer.bitmap_info.bmiHeader);
    ; bmiHeader offset is 0
    mov DWORD [rcx], 40             ; biSize offset is 0
    mov DWORD [rcx + 4], edx        ; biWidth offset is 4
    neg r8d
    mov DWORD [rcx + 8], r8d        ; biHeight offset is 8
    mov WORD [rcx + 24], 1          ; biPlanes offset is 12
    mov WORD [rcx + 32], 32         ; biBitCount offset is 14
    mov DWORD [rcx + 40], 0         ; biCompression offset is 16, value is BI_RGB


    xor rcx, rcx                    ; single argument, 0
    call CreateCompatibleDC         

    mov rcx, [buffer]
    mov [rcx + 16], rax             ; frame_device_context offset is 16

    ; call CreateDIBSection

    sub rsp, 16                     ; 2 stack parameters, rsp is still 16 byte aligned

    mov rdx, [rcx + bitmap_info_offset]     ; buffer.bitmap_info
    mov r9, rcx                     ; buffer.pixels, offset is 0
    mov rcx, 0                      ; NULL
    mov r8, 0                       ; DIB_RGB_COLORS
    mov QWORD [rbp - 5 * 8], 0
    mov QWORD [rbp - 6 * 8], 0
    call CreateDIBSection
    add rsp, 16                     ; clear the parameter space


    mov rcx, [buffer + 16]          ; frame_device_context offset is 16
    mov rdx, rax
    call SelectObject


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
    ; 32 bytes of shadow space + 192 bytes for local variables + 0 bytes for 16 byte alignement
    sub     rsp, 224                                 

    ; hInstance in rcx
    ; hPrevInstance in rdx
    ; pCmdLine in r8
    ; nCmdShow in r9

    lea rax, [digits_buffer_pixels]
    mov [digits_buffer.pixels], rax

    %define window_class                        rbp - 72    ; WNDCLASSW structure, 72 bytes, aligned on an 8 byte boundary

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


    ; =======================
    ; initialize window_class
    ; =======================

    mov DWORD [window_class.style], 0

    lea rax, [WindowProcessMessage]
    mov [window_class.lpfnWndProc], rax

    mov QWORD [window_class.cbClsExtra], 0     ; fill cbClsExtra and cbWndExtra with 0 at the same time

    mov [window_class.hInstance], rcx

    mov QWORD [window_class.hIcon], 0
    mov QWORD [window_class.hCursor], 0

    ; window_class.hbrBackground = (HBRUSH)GetStockObject(BLACK_BRUSH);
    mov QWORD rcx, 4                   ; BLACK_BRUSH
    call GetStockObject
    mov [window_class.hbrBackground], rax

    mov QWORD [window_class.lpszMenuName], 0

    lea rax, [rel window_name]
    mov [window_class.lpszClassName], rax

    ; register class
    lea rcx, [window_class]
    call RegisterClassW

    ; ==================
    ; initialize buffers
    ; ==================

    mov DWORD [rel draw_buffer.width], WINDOW_Y
    mov DWORD [rel draw_buffer.height], WINDOW_Y
    
    lea rax, [rel draw_buffer_pixels]
    mov QWORD [rel draw_buffer.pixels], rax

    mov DWORD [digits_buffer.width], DIGITS_IMAGE_X
    mov DWORD [digits_buffer.height], DIGITS_IMAGE_Y
    
    lea rax, [rel digits_buffer_pixels]
    mov QWORD [rel draw_buffer.pixels], rax

    ; initialize_device_context for draw_buffer

    lea rcx, [rel draw_buffer]
    mov rdx, WINDOW_X
    mov r8, WINDOW_Y
    call initialize_device_context

    ; initialize_device_context for draw_buffer

    lea rcx, [rel digits_buffer]
    mov rdx, DIGITS_IMAGE_X
    mov r8, DIGITS_IMAGE_Y
    call initialize_device_context

    mov rcx, [digits_buffer.pixels]
    call load_digit_image

    lea rcx, [rel saved_digits_buffer]
    call load_digit_image

    ; ===========================
    ; load neural network weights
    ; ===========================

    lea rcx, [rel dense1_weights]
    lea rdx, [rel dense1_bias]
    lea r8, [rel dense2_weights]
    lea r9, [rel dense2_bias]
    call load_weights

    %define window_rect                     window_class - 16

    %define window_rect.left                window_class - 16           ; LONG, 4 bytes
    %define window_rect.top                 window_class - 12           ; LONG, 4 bytes
    %define window_rect.right               window_class - 8            ; LONG, 4 bytes
    %define window_rect.bottom              window_class - 4            ; LONG, 4 bytes

    mov DWORD [window_rect.left], 0
    mov DWORD [window_rect.top], 0
    mov DWORD [window_rect.right], WINDOW_X
    mov DWORD [window_rect.bottom], WINDOW_Y

    lea rcx, [window_rect]
    mov rdx, 0xCA0000                       ; WS_OVERLAPPEDWINDOW & (~(WS_THICKFRAME | WS_MAXIMIZEBOX))
    xor r8, r8                              ; FALSE
    call AdjustWindowRect

    ; =============
    ; create window
    ; =============

    sub rsp, 64                             ; 8 stack parameters, rsp is still 16 byte aligned
    lea rcx, [rel window_name]
    lea rdx, [rel window_name]
    mov r8, 0x10CA0000                      ; (WS_OVERLAPPEDWINDOW | WS_VISIBLE) & (~(WS_THICKFRAME | WS_MAXIMIZEBOX))
    mov r9, 440

    mov QWORD [rsp + 5 * 8], 120

    mov rax, [window_rect.right]
    sub rax, [window_rect.left]
    mov QWORD [rsp + 6 * 8], rax

    mov rax, [window_rect.bottom]
    sub rax, [window_rect.top]
    mov QWORD [rsp + 7 * 8], rax

    mov QWORD [rsp + 8 * 8], 0              ; NULL
    mov QWORD [rsp + 9 * 8], 0              ; NULL

    lea rax, [rel hInstance]
    mov QWORD [rsp + 10 * 8], rax

    mov QWORD [rsp + 11 * 8], 0             ; NULL
    call CreateWindowExW
    add rsp, 64                             ; clear the parameter space



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
    mov QWORD [message], 0

    .while:
    lea rcx, [message]
    mov rdx, 0                              ; NULL
    mov r8, 0
    mov r9, 0
    mov QWORD [message - 8], 0x0001               ; PM_REMOVE
    call PeekMessageW

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

    cmp BYTE [rel quit], 0
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
    sub     rsp, 80                                 ; Reserve 32 bytes of shadow space + 48 bytes for local variables
    
    %define window_handle                           rbp - 32
    %define message                                 rbp - 24
    %define wParam                                  rbp - 16
    %define lParam                                  rbp - 8

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
    jmp .break

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
    and rdx, 0x0000ffff
    mov r8, [lParam]
    shr r8, 16
    call update_on_mouse_click

    mov rcx, [rel draw_buffer.pixels]
    mov rdx, [rel mnist_array]
    call get_draw_region_features

    lea rcx, [window_handle]
    mov rdx, 0              ; NULL
    mov r8, 0               ; FALSE
    call InvalidateRect
    jmp .break

    .lmb_up:
    mov BYTE [rel lmb_down], 0
    call ReleaseCapture
    jmp .break

    .rmb_down:
    lea rcx, [rel draw_buffer.pixels]
    call clear_draw_region
    jmp .break

    .key_down:
    cmp QWORD [wParam], 0x20          ; VK_SPACE
    jne .break

    xor rax, rax
    .loop:
    lea rcx, [rel saved_digits_buffer]
    mov rcx, [rcx + rax]

    lea r10, [rel digits_buffer_pixels]
    mov [r10 + rax], rcx

    inc rax
    cmp rax, DIGITS_IMAGE_BYTE_SIZE
    jle .loop

    ; ================
    ; call run_network
    ; ================

    sub rsp, 2 * 8                             ; 2 stack parameters, rsp is still 16 byte aligned
    lea rcx, [rel mnist_array]
    lea rdx, [rel dense1_weights]
    lea r8, [rel dense1_bias]
    lea r9, [rel dense2_weights]
    lea rax, [rel dense2_bias]
    mov QWORD [rsp + 5 * 8], rax
    lea rax, [rel output_buffer]
    mov QWORD [rsp + 6 * 8], rax
    call run_network
    add rsp, 16                                ; clear parameter space

    mov rcx, [rel output_buffer]
    xor r8, r8
    mov rax, 1
    .loop2:
    lea r10, [rel output_buffer]
    mov r10, [r10 + rax]
    cmp rcx, r10
    jle .keep
    mov rcx, r10
    mov r8, rax
    .keep:

    inc rax
    cmp rax, DENSE2_SIZE
    jle .loop2

    lea rcx, [rel digits_buffer_pixels]
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
    mov BYTE [rel lmb_down], BYTE 0
    jmp .break

    .paint:

    lea rcx, [window_handle]
    lea rdx, [rel paint]
    call BeginPaint

    %define device_context                          window_handle - 8
    mov [device_context], rax

    ; call BitBlt twice

    sub rsp, 5 * 8                                  ; 5 stack parameters, rsp is still 16 byte aligned
    mov rcx, [device_context]
    xor rdx, rdx
    xor r8, r8
    mov r9, WINDOW_Y

    mov QWORD [rsp + 5 * 8], WINDOW_Y
    mov QWORD [rsp + 6 * 8], draw_buffer.frame_device_context
    mov QWORD [rsp + 7 * 8], 0
    mov QWORD [rsp + 8 * 8], 0
    mov QWORD [rsp + 9 * 8], 0x00CC0020             ; SRCCOPY
    call BitBlt

    mov rcx, [device_context]
    mov rdx, WINDOW_Y + 10
    xor r8, r8
    mov r9, DIGITS_IMAGE_X

    mov QWORD [rsp + 5 * 8], DIGITS_IMAGE_Y
    mov QWORD [rsp + 6 * 8], draw_buffer.frame_device_context
    mov QWORD [rsp + 7 * 8], 0
    mov QWORD [rsp + 8 * 8], 0
    mov QWORD [rsp + 9 * 8], 0x00CC0020             ; SRCCOPY
    call BitBlt

    sub rsp, 5 * 8                                  ; clear parameter space


    lea rcx, [window_handle]
    lea rdx, [rel paint]
    call EndPaint
    jmp .break

    .break:
    ; Function epilogue
    xor rax, rax                  ; Return 0
    
    mov rsp, rbp ; Deallocate local variables
    pop rbp ; Restore the caller's base pointer value
    ret