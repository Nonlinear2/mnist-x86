global initialize_device_context


extern CreateCompatibleDC
extern CreateDIBSection
extern SelectObject


%define bitmap_info_offset                      28

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

    %define device_context                          rbp - 8
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