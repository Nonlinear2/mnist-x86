global draw_pixel
global draw_square
global clear_draw_region
global get_draw_region_features
global update_on_mouse_click
global draw_pixel_on_digits
global load_digit_image
global draw_circle_on_digits

section .data
align 8
digits_data: incbin "./digits_images/all_digits.data"
digits_size equ $ - digits_data

section .text
; WINDOW_Y must be a multiple of 28
%define WINDOW_X                    650
%define WINDOW_Y                    560
%define MNIST_SIZE                  28
%define DRAW_REGION_SIZE            WINDOW_Y
%define SCALE                       WINDOW_Y / MNIST_SIZE
%define DIGITS_IMAGE_X              50
%define DIGITS_IMAGE_Y              560

; void draw_pixel(uint8_t* draw_buffer, int x, int y, uint8_t value)
draw_pixel:
    ; Function prologue
    push    rbp
    mov     rbp, rsp
    sub     rsp, 32                                 ; Reserve 32 bytes of shadow space
    
    ; buffer pointer in rcx
    ; mouse x position in rdx
    ; mouse y position in r8
    ; value in r9

    ; draw_buffer[4*(DRAW_REGION_SIZE*y + x)] = value;
    imul r8, DRAW_REGION_SIZE
    add r8, rdx
    mov byte [rcx + 4 * r8], r9b

    ; Function epilogue
    xor rax, rax                                    ; Return 0
    mov rsp, rbp                                    ; Deallocate local variables
    pop rbp                                         ; Restore the caller's base pointer value
    ret


; void draw_square(uint8_t* draw_buffer, int x, int y);
draw_square:
    ; Function prologue
    push    rbp
    mov     rbp, rsp
    sub     rsp, 32                                 ; Reserve 32 bytes of shadow space
    
    ; buffer pointer in rcx
    ; mouse x position in rdx
    ; mouse y position in r8

    ; bounds checks:
    cmp rdx, 0
    jl .return

    cmp rdx, DRAW_REGION_SIZE
    jge .return

    cmp r8, 0
    jl .return

    cmp r8, DRAW_REGION_SIZE
    jge .return

    ; nested loop to draw a square
    xor rax, rax                                    ; set rax to 0
    .loop:

    xor r10, r10                                    ; set r10 to 0
    .inner_loop:

    ; draw_buffer[((y + j) * DRAW_REGION_SIZE + (x + i)) * 4] = 255;
    mov r9, r8
    add r9, r10
    imul r9, DRAW_REGION_SIZE
    add r9, rdx
    add r9, rax
    mov byte [rcx + 4 * r9], 255

    inc r10
    cmp r10, SCALE
    jl .inner_loop

    inc rax
    cmp rax, SCALE
    jl .loop

    .return:
    ; Function epilogue
    xor rax, rax                                    ; Return 0
    mov rsp, rbp                                    ; Deallocate local variables
    pop rbp                                         ; Restore the caller's base pointer value
    ret


; void clear_draw_region(uint8_t* buffer);
clear_draw_region:
    ; Function prologue
    push    rbp
    mov     rbp, rsp
    sub     rsp, 32                                 ; Reserve 32 bytes of shadow space
    
    ; buffer pointer in rcx

    mov QWORD rax, DRAW_REGION_SIZE
    imul rax, DRAW_REGION_SIZE
    ; rax now has the size of the window

    shl rax, 2                                      ; multiply the index by 4, because it is an RBBA array

    xor rdx, rdx                                    ; set rdx to 0
    .first_loop:                                    ; clear all values
    mov byte [rcx + rdx], 0                            
    inc rdx
    cmp rdx, rax
    jl .first_loop


    shr rax, 2

    add QWORD rcx, 3                                ; offset to access alpha channel

    xor rdx, rdx                                    ; set rdx to 0
    .second_loop:
    mov byte [rcx + 4 * rdx], 255                     ; set the alpha value to 255
    inc rdx
    cmp rdx, rax
    jl .second_loop

    sub QWORD rcx, 3                                ; restore the value of rcx

    ; Function epilogue
    xor rax, rax                                    ; Return 0
    mov rsp, rbp                                    ; Deallocate local variables
    pop rbp                                         ; Restore the caller's base pointer value
    ret


; void get_draw_region_features(uint8_t* draw_buffer, uint8_t* out_buffer);
get_draw_region_features:
    ; Function prologue
    push    rbp
    mov     rbp, rsp
    sub     rsp, 32                                 ; Reserve 32 bytes of shadow space
    
    ; input buffer pointer in rcx
    ; output buffer pointer in rdx

    ; nested loop to draw a square
    xor rax, rax                                    ; set rax to 0
    .loop:

    xor r10, r10                                    ; set r10 to 0
    .inner_loop:

    ; out_buffer[y * MNIST_SIZE + x] = draw_buffer[(y * SCALE * DRAW_REGION_SIZE + x * SCALE) * 4];
    mov r8, rax
    imul r8, SCALE
    imul r8, DRAW_REGION_SIZE
    mov r9, r10
    imul r9, SCALE
    add r8, r9
    shl r8, 2                                       ; multiply by 4

    mov r9, rax
    imul r9, MNIST_SIZE
    add r9, r10

    mov r8b, byte [rcx + r8]
    mov byte [rdx + r9], r8b

    inc r10
    cmp r10, SCALE
    jl .inner_loop

    inc rax
    cmp rax, SCALE
    jl .loop

    ; Function epilogue
    xor rax, rax                                    ; Return 0
    mov rsp, rbp                                    ; Deallocate local variables
    pop rbp                                         ; Restore the caller's base pointer value
    ret

; void update_on_mouse_click(uint8_t* draw_buffer, int x, int y);
update_on_mouse_click:
    ; Function prologue
    push    rbp
    mov     rbp, rsp
    sub     rsp, 32                                 ; Reserve 32 bytes of shadow space
    
    ; buffer pointer in rcx
    ; mouse x position in rdx
    ; mouse y position in r8

    mov r10, SCALE

    ; x = x / SCALE * SCALE;
    mov rax, rdx
    xor rdx, rdx                                    ; the upper 64 bits of the dividend are 0
    div r10                                         ; rdx gets modified, it now contains the remainder
    imul r10
    mov r9, rax

    ; y = y / SCALE * SCALE;
    mov rax, r8
    xor rdx, rdx
    div r10                                         ; rdx gets modified, it now contains the remainder
    imul r10
    mov r8, rax

    mov rdx, r9

    ; save the parameters
    push r8     ; y
    push rdx    ; x
    push rcx    ; buffer pointer


    ; draw_square(draw_buffer, x, y);
    call draw_square

    ; registers may have been modified, so we restore them
    mov rcx, [rsp]          ; buffer pointer
    mov rdx, [rsp + 8]      ; x
    mov r8, [rsp + 16]      ; y

    sub rdx, SCALE

    ; draw_square(draw_buffer, x-SCALE, y);
    call draw_square

    mov rcx, [rsp]          ; buffer pointer
    mov rdx, [rsp + 8]      ; x
    mov r8, [rsp + 16]      ; y

    add rdx, SCALE

    ; draw_square(draw_buffer, x+SCALE, y);
    call draw_square

    mov rcx, [rsp]          ; buffer pointer
    mov rdx, [rsp + 8]      ; x
    mov r8, [rsp + 16]      ; y

    sub r8, SCALE

    ; draw_square(draw_buffer, x, y-SCALE);
    call draw_square

    mov rcx, [rsp]          ; buffer pointer
    mov rdx, [rsp + 8]      ; x
    mov r8, [rsp + 16]      ; y

    add r8, SCALE

    ; draw_square(draw_buffer, x, y+SCALE);
    call draw_square

    ; Function epilogue
    xor rax, rax                                    ; return 0
    mov rsp, rbp                                    ; deallocate local variables
    pop rbp                                         ; restore the caller's base pointer value
    ret

; void draw_pixel_on_digits(uint8_t* digits_buffer, int x, int y, int value);
draw_pixel_on_digits:
    ; Function prologue
    push    rbp
    mov     rbp, rsp
    sub     rsp, 32                                 ; reserve 32 bytes of shadow space
    
    ; buffer pointer in rcx
    ; mouse x position in rdx
    ; mouse y position in r8
    ; value in r9

    ; bounds checks:
    cmp rdx, 0
    jl .return

    cmp rdx, DIGITS_IMAGE_X
    jge .return

    cmp r8, 0
    jl .return

    cmp r8, DIGITS_IMAGE_Y
    jge .return

    imul r8, DIGITS_IMAGE_X
    add r8, rdx
    
    mov byte [rcx + 4 * r8], r9b

    .return:
    ; Function epilogue
    xor rax, rax                                    ; Return 0
    mov rsp, rbp                                    ; Deallocate local variables
    pop rbp                                         ; Restore the caller's base pointer value
    ret

; void load_digit_image(uint8_t* digits_buffer);
load_digit_image:
    ; Function prologue
    push    rbp
    mov     rbp, rsp
    sub     rsp, 32                                 ; Reserve 32 bytes of shadow space
    
    ; buffer pointer in rcx

    push rdi                                        ; callee-saved
    push rsi                                        ; callee-saved

    lea rsi, [rel digits_data]                      ; source
    mov rdi, rcx                                    ; destination
    mov rcx, digits_size

    cld                                             ; clear direction flag (ensure forward copy)
    rep movsb                                       ; copy rcx bytes from [rsi] to [rdi]

    pop rsi
    pop rdi

    ; Function epilogue
    xor rax, rax                                    ; Return 0
    mov rsp, rbp                                    ; Deallocate local variables
    pop rbp                                         ; Restore the caller's base pointer value
    ret

; void draw_circle_on_digits(uint8_t* digits_buffer, int center_x, int center_y, int r);
draw_circle_on_digits:
    ; Function prologue
    push    rbp
    mov     rbp, rsp
    sub     rsp, 80                                 ; Reserve 32 bytes of shadow space + 48 bytes for local variables
    
    ; buffer pointer in rcx
    ; center_x in rdx
    ; center_y in r8
    ; r in r9

    %define digits_buffer [rbp - 8]
    %define center_x      [rbp - 16]
    %define center_y      [rbp - 24]
    %define x             [rbp - 32]
    %define y             [rbp - 40]
    %define p             [rbp - 48]

    mov digits_buffer, rcx
    mov center_x, rdx
    mov center_y, r8
    mov QWORD x, QWORD 0

    neg r9
    mov y, r9
    mov p, r9

    ; midpoint circle algorithm
    .while:
    mov rax, y
    neg rax
    cmp QWORD x, rax
    jge .break

    cmp QWORD p, 0
    jle .else
    inc QWORD y
    mov r11, x
    add r11, y
    shl r11, 1
    inc r11
    jmp .endif
    .else:
    mov r11, x
    shl r11, 1
    inc r11
    .endif:
    add p, r11

    ; draw_pixel_on_digits(digits_buffer, center_x + x, center_y + y, 255);

    ; buffer pointer in rcx
    mov rcx, digits_buffer

    ; center_x + x in rdx
    mov rdx, center_x
    add rdx, x
    ; center_y + y position in r8
    mov r8, center_y
    add r8, y
    ; 255 in r9
    mov r9, 255

    call draw_pixel_on_digits

    ; draw_pixel_on_digits(digits_buffer, center_x - x, center_y + y, 255);

    ; buffer pointer in rcx
    mov rcx, digits_buffer
    ; center_x - x in rdx
    mov rdx, center_x
    sub rdx, x
    ; center_y + y position in r8
    mov r8, center_y
    add r8, y
    ; 255 in r9
    mov r9, 255

    call draw_pixel_on_digits

    ; buffer pointer in rcx
    mov rcx, digits_buffer
    ; center_x + x in rdx
    mov rdx, center_x
    add rdx, x
    ; center_y - y position in r8
    mov r8, center_y
    sub r8, y
    ; 255 in r9
    mov r9, 255

    call draw_pixel_on_digits

    ; buffer pointer in rcx
    mov rcx, digits_buffer
    ; center_x - x in rdx
    mov rdx, center_x
    sub rdx, x
    ; center_y - y position in r8
    mov r8, center_y
    sub r8, y
    ; 255 in r9
    mov r9, 255

    call draw_pixel_on_digits

    ; buffer pointer in rcx
    mov rcx, digits_buffer
    ; center_x + y in rdx
    mov rdx, center_x
    add rdx, y
    ; center_y + x position in r8
    mov r8, center_y
    add r8, x
    ; 255 in r9
    mov r9, 255

    call draw_pixel_on_digits

    ; buffer pointer in rcx
    mov rcx, digits_buffer
    ; center_x + y in rdx
    mov rdx, center_x
    add rdx, y
    ; center_y - x position in r8
    mov r8, center_y
    sub r8, x
    ; 255 in r9
    mov r9, 255

    call draw_pixel_on_digits

    ; buffer pointer in rcx
    mov rcx, digits_buffer
    ; center_x - y in rdx
    mov rdx, center_x
    sub rdx, y
    ; center_y + x position in r8
    mov r8, center_y
    add r8, x
    ; 255 in r9
    mov r9, 255

    call draw_pixel_on_digits

    ; buffer pointer in rcx
    mov rcx, digits_buffer
    ; center_x - y in rdx
    mov rdx, center_x
    sub rdx, y
    ; center_y - x position in r8
    mov r8, center_y
    sub r8, x
    ; 255 in r9
    mov r9, 255

    call draw_pixel_on_digits

    inc QWORD x
    jmp .while
    .break:

    ; Function epilogue
    xor rax, rax                  ; Return 0

    mov rsp, rbp ; Deallocate local variables
    pop rbp ; Restore the caller's base pointer value
    ret