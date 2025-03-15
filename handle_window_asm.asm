global draw_pixel
global draw_square
global clear_draw_region
global get_draw_region_features
global update_on_mouse_click
global draw_pixel_on_digits

extern printf


section .data
message db 'value is %d', 10, 0                      ; 10 is newline, 0 is string terminator


section .text


; window_y must be a multiple of 28
%define window_x 650
%define window_y 560

%define mnist_size 28

%define draw_region_size window_y

%define scale window_y / mnist_size

%define digits_image_x 50
%define digits_image_y 560

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

    ; draw_buffer[4*(draw_region_size*y + x)] = value;
    imul r8, draw_region_size
    add r8, rdx
    shl r8, 2                   ; multiply by 4
    mov byte [rcx + r8], r9b

    ; Function epilogue
    mov rax, 0                  ; Return 0

    mov rsp, rbp ; Deallocate local variables
    pop rbp ; Restore the caller's base pointer value
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

    cmp rdx, draw_region_size
    jge .return

    cmp r8, 0
    jl .return

    cmp r8, draw_region_size
    jge .return

    ; nested loop to draw a square
    xor rax, rax                                       ; set rax to 0
    .loop:

    xor r10, r10                                       ; set r10 to 0
    .inner_loop:

    ; draw_buffer[((y + j) * draw_region_size + (x + i)) * 4] = 255;
    mov r9, r8
    add r9, r10
    imul r9, draw_region_size
    add r9, rdx
    add r9, rax
    shl r9, 2       ; multiply by 4
    mov byte [rcx + r9], 255

    inc r10
    cmp r10, scale
    jl .inner_loop

    inc rax
    cmp rax, scale
    jl .loop

    .return:
    ; Function epilogue
    mov rax, 0                  ; Return 0

    mov rsp, rbp ; Deallocate local variables
    pop rbp ; Restore the caller's base pointer value
    ret


; void clear_draw_region(uint8_t* buffer);
clear_draw_region:
    ; Function prologue
    push    rbp
    mov     rbp, rsp
    sub     rsp, 32                                    ; Reserve 32 bytes of shadow space
    
    ; buffer pointer in rcx

    mov QWORD rax, draw_region_size
    imul rax, draw_region_size
    ; rax now has the size of the window

    shl rax, 2                                         ; multiply the index by 4, because it is an RBBA array
    ; now has 4 times the size of the window

    xor rdx, rdx                                       ; set rdx to 0
    .first_loop:                                        ; clear all values
    mov byte [rcx + rdx], 0                            
    inc rdx
    cmp rdx, rax
    jl .first_loop


    shr eax, 2

    add QWORD rcx, 3                                   ; offset to access alpha channel

    xor rdx, rdx                                       ; set rdx to 0
    .second_loop:
    mov byte [rcx + 4*rdx], 255                        ; set the alpha value to 255
    inc rdx
    cmp rdx, rax
    jl .second_loop

    sub QWORD rcx, 3                                   ; restore the value of rcx

    ; Function epilogue
    mov rax, 0                  ; Return 0

    mov rsp, rbp ; Deallocate local variables
    pop rbp ; Restore the caller's base pointer value
    ret


; void get_draw_region_features(uint8_t* draw_buffer, uint8_t* out_buffer);
get_draw_region_features:
    ; Function prologue
    push    rbp
    mov     rbp, rsp
    sub     rsp, 32                                    ; Reserve 32 bytes of shadow space
    
    ; input buffer pointer in rcx
    ; output buffer pointer in rdx

    ; nested loop to draw a square
    xor rax, rax                                       ; set rax to 0
    .loop:

    xor r10, r10                                       ; set r10 to 0
    .inner_loop:

    ; out_buffer[y * mnist_size + x] = draw_buffer[(y * scale * draw_region_size + x * scale) * 4];
    mov r8, rax
    imul r8, scale
    imul r8, draw_region_size
    mov r9, r10
    imul r9, scale
    add r8, r9
    shl r8, 2                   ; multiply by 4

    mov r9, rax
    imul r9, mnist_size
    add r9, r10

    mov r8b, byte [rcx + r8]
    mov byte [rdx + r9], r8b

    inc r10
    cmp r10, scale
    jl .inner_loop

    inc rax
    cmp rax, scale
    jl .loop

    ; Function epilogue
    mov rax, 0                  ; Return 0

    mov rsp, rbp ; Deallocate local variables
    pop rbp ; Restore the caller's base pointer value
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

    mov r10, scale

    ; x = x / scale * scale;
    mov rax, rdx
    xor rdx, rdx ; the upper 64 bits of the dividend are 0
    div r10 ; rdx gets modified! it now contains the remainder
    imul r10
    mov r9, rax
    
    ; y = y / scale * scale;
    mov rax, r8
    xor rdx, rdx
    div r10
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

    sub rdx, scale

    ; draw_square(draw_buffer, x-scale, y);
    call draw_square

    mov rcx, [rsp]          ; buffer pointer
    mov rdx, [rsp + 8]      ; x
    mov r8, [rsp + 16]      ; y

    add rdx, scale

    ; draw_square(draw_buffer, x+scale, y);
    call draw_square

    mov rcx, [rsp]          ; buffer pointer
    mov rdx, [rsp + 8]      ; x
    mov r8, [rsp + 16]      ; y

    sub r8, scale

    ; draw_square(draw_buffer, x, y-scale);
    call draw_square

    mov rcx, [rsp]          ; buffer pointer
    mov rdx, [rsp + 8]      ; x
    mov r8, [rsp + 16]      ; y

    add r8, scale

    ; draw_square(draw_buffer, x, y+scale);
    call draw_square

    ; Function epilogue
    mov rax, 0                  ; Return 0

    mov rsp, rbp ; Deallocate local variables
    pop rbp ; Restore the caller's base pointer value
    ret

; void draw_pixel_on_digits(uint8_t* digits_buffer, int x, int y, int value);
draw_pixel_on_digits:
    ; Function prologue
    push    rbp
    mov     rbp, rsp
    sub     rsp, 32                                 ; Reserve 32 bytes of shadow space
    
    ; buffer pointer in rcx
    ; mouse x position in rdx
    ; mouse y position in r8
    ; value in r9

    ; bounds checks:
    cmp rdx, 0
    jl .return

    cmp rdx, digits_image_x
    jge .return

    cmp r8, 0
    jl .return

    cmp r8, digits_image_y
    jge .return

    imul r8, digits_image_x
    add r8, rdx
    shl r8, 2           ; multiply by 4
    
    mov byte [rcx + r8], r9b

    .return:
    ; Function epilogue
    mov rax, 0                  ; Return 0

    mov rsp, rbp ; Deallocate local variables
    pop rbp ; Restore the caller's base pointer value
    ret




; ; ; void quantize_screen(uint8_t* in_buffer, uint8_t* out_buffer);
; ; ; in buffer is an rgba array of size window_x * window_y * 4
; ; ; out_buffer is a grayscale array of size 28 * 28
; ; quantize_screen:
; ;     ; Function prologue
; ;     push    rbp
; ;     mov     rbp, rsp
; ;     sub     rsp, 48                                    ; Reserve 32 bytes of shadow space + 16 for local variables

; ;     ; in_buffer pointer in rcx
; ;     ; out_buffer pointer in rdx


; ;     mov QWORD rax, window_x
; ;     div 28                                             ; mnist sample size
; ;     mov [rbp - 8], rax                                 ; [rbp - 8] contains the scale factor


; ;     xor r8, r8                                       ; r8 will be our outer loop variable
; ;     output_pixel_loop_y:
; ;         xor r9, r9                                       
; ;         output_pixel_loop_x:
; ;             mov [rdx + r8], 0                             ; clear out_buffer value

; ;             xor rax, rax                                   ; rax will be the accumulator

; ;             mov rbx, rcx    ; load the input buffer adress
; ;             add rbx, r8*(rbp-8)*window_x * 4 ; add y coordinate times scale times window_x
; ;             add rbx, r9*(rbp-8) * 4 ; add x coordinate

; ;             ; now rbx contains the index of the upper left pixel of the square to be quantized
            
; ;             xor r10, r10                                   
; ;             input_pixel_loop_x:
; ;                 input_pixel_loop_x:            
; ;                 inc r10
; ;                 cmp r10, [rbp - 8]
; ;                 jl output_pixel_loop_x     
                   
; ;                 inc r10
; ;                 cmp r10, [rbp - 8]
; ;                 jl output_pixel_loop_x           

; ;             inc r9
; ;             cmp r9, 28
; ;             jl output_pixel_loop_x
; ;         inc r8
; ;         cmp r8, 28
; ;         jl output_pixel_loop_y
        

; ;     ; Function epilogue
; ;     mov rax, 0                  ; Return 0

; ;     mov rsp, rbp ; Deallocate local variables
; ;     pop rbp ; Restore the caller's base pointer value
; ;     ret

; ;     ; ; Call printf
; ;     ; lea     rcx, [rel message]   ; First parameter for printf
; ;     ; mov rdx, rax ; second parameter for printf
; ;     ; call    printf