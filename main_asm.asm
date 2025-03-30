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
%define DRAW_REGION_SIZE            window_y
%define SCALE                       window_y / mnist_size
%define DIGITS_IMAGE_X              50
%define DIGITS_IMAGE_Y              560

section .data
window_name db "MNIST-x86", 0

quit db 0
lmb_down db 0

align 8
buffer1:    
    dq 0                        ; pixels (8 bytes, 8 bytes aligned)
    dq 0                        ; bitmap (8 bytes, 8 bytes aligned)
    dq 0                        ; frame_device_context (8 bytes, 8 bytes aligned)
    dd 1920                     ; width (4 bytes, 4 bytes aligned)
    dd 1080                     ; height (4 bytes, 4 bytes aligned)
    times 44 db 0               ; bitmap_info (44 bytes, 4 bytes aligned)
    times 4 db 0                ; Padding for alignment

align 8
buffer2:    
    dd 1280
    dd 720
    dq 0
    times 44 db 0
    dq 0
    dq 0
    times 4 db 0



section .bss
align 8
hInstance resq 1

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

WinMain:
    ; Function prologue
    push    rbp
    mov     rbp, rsp
    sub     rsp, 32                                 ; Reserve 32 bytes of shadow space


