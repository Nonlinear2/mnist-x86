; global update_on_mouse_click
; global clear_draw_region
global update_draw_region_pixel
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

; void update_draw_region_pixel(uint8_t* draw_buffer, int x, int y);
update_draw_region_pixel:
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

    xor rbx, rbx                                       ; set rbx to 0
    .inner_loop:

    ; draw_buffer[((y + j) * draw_region_size + (x + i)) * 4] = 255;
    mov r9, r8
    add r9, rbx
    imul r9, draw_region_size
    add r9, rdx
    add r9, rax
    shl r9, 2       ; multiply by 4
    mov byte [rcx + r9], 255

    inc rbx
    cmp rbx, draw_region_size
    jl .inner_loop

    inc rax
    cmp rax, draw_region_size
    jl .loop

    .return:
    ; Function epilogue
    mov eax, 0                  ; Return 0

    mov rsp, rbp ; Deallocate local variables
    pop rbp ; Restore the caller's base pointer value
    ret

; ; void update_on_mouse_click(uint8_t* draw_buffer, int x, int y);
; update_on_mouse_click:
;     ; Function prologue
;     push    rbp
;     mov     rbp, rsp
;     sub     rsp, 32                                 ; Reserve 32 bytes of shadow space
    
;     ; buffer pointer in rcx
;     ; mouse x position in rdx
;     ; mouse y position in r8

;     ; bounds checks:
;     cmp rdx, 0
;     jl return

;     cmp rdx, window_size
;     jge return

;     cmp r8, 0
;     jl return

;     cmp r8, window_size
;     jge return

;     imul r8d, window_size                                 ; r8d    = r8d * window_size
;     add  r8,  rdx                                      ; r8d += mouse x position
;     ; now contains the index of the pixel to be set.

;     shl r8d, 2                                       ; multiply the index by 4, because it is an RBBA array
    
;     mov byte [rcx + r8], 255                         ; set the red value to 255

;     return:
;     ; Function epilogue
;     mov eax, 0                  ; Return 0

;     mov rsp, rbp ; Deallocate local variables
;     pop rbp ; Restore the caller's base pointer value
;     ret

; ; void clear_draw_region(uint8_t* buffer);
; clear_draw_region:
;     ; Function prologue
;     push    rbp
;     mov     rbp, rsp
;     sub     rsp, 32                                    ; Reserve 32 bytes of shadow space
    
;     ; buffer pointer in rcx

;     mov QWORD rax, window_size
;     mov QWORD r9, window_size
;     mul r9                                             ; rdx:rax = rax * r9d
;     ; rax now has the size of the window

;     shl eax, 2                                         ; multiply the index by 4, because it is an RBBA array
;     ; now has 4 times the size of the window

;     xor rbx, rbx                                       ; set rbx to 0
;     first_loop:                                        ; clear all values
;     mov byte [rcx + rbx], 0                            
;     inc rbx
;     cmp rbx, rax
;     jl first_loop


;     shr eax, 2

;     add QWORD rcx, 3                                   ; offset to access alpha channel

;     xor rbx, rbx                                       ; set rbx to 0
;     second_loop:
;     mov rdx, rbx
;     mov byte [rcx + 4*rbx], 255                        ; set the alpha value to 255
;     inc rbx
;     cmp rbx, rax
;     jl second_loop

;     sub QWORD rcx, 3                                   ; restore the value of rcx

;     ; Function epilogue
;     mov eax, 0                  ; Return 0

;     mov rsp, rbp ; Deallocate local variables
;     pop rbp ; Restore the caller's base pointer value
;     ret

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
; ;     mov eax, 0                  ; Return 0

; ;     mov rsp, rbp ; Deallocate local variables
; ;     pop rbp ; Restore the caller's base pointer value
; ;     ret

; ;     ; ; Call printf
; ;     ; lea     rcx, [rel message]   ; First parameter for printf
; ;     ; mov rdx, rax ; second parameter for printf
; ;     ; call    printf