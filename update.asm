global update
global clear
extern printf


section .data
message db 'value is %d', 10, 0    ; 10 is newline, 0 is string terminator


section .text
window_x equ 150
window_y equ 150

update:
    ; Function prologue
    push    rbp
    mov     rbp, rsp
    sub     rsp, 48                                 ; Reserve 32 bytes of shadow space + 16 for local variables
    
    ; store the mouse position

    ; rcx is the buffer pointer
    ; mouse x position in rdx
    ; mouse y position in r8

    mov rax, r8                                      ; load y position in eax

    mov r10, rdx                                     ; save rdx before calling the mul instruction            
    mov r9d, window_x                                ; Load window_x into a register
    mul r9d                                          ; edx:eax = eax * r9d
    add rax, r10                                     ; rax += mouse x position
    ; now contains the index of the pixel to be set.

    shl eax, 2                                       ; multiply the index by 4, because it is an RBBA array
    
    mov byte [rcx + rax], 255                        ; set the red value to 255

    ; Function epilogue
    mov eax, 0                  ; Return 0

    mov rsp, rbp ; Deallocate local variables
    pop rbp ; Restore the caller's base pointer value
    ret

clear:
    ; Function prologue
    push    rbp
    mov     rbp, rsp
    sub     rsp, 48                                 ; Reserve 32 bytes of shadow space + 16 for local variables
    
    ; store the mouse position

    ; rcx is the buffer pointer

    mov QWORD rax, window_x
    mov QWORD r9, window_y
    mul r9                                             ; rdx:rax = rax * r9d
    ; rax now has the size of the window

    shl eax, 2                                         ; multiply the index by 4, because it is an RBBA array
    ; now has 4 times the size of the window

    xor rbx, rbx                                       ; set rbx to 0
first_loop:                                            ; clear all values
    mov byte [rcx + rbx], 0                            
    inc rbx
    cmp rbx, rax
    jl first_loop


    shr eax, 2
    xor rbx, rbx                                       ; set rbx to 0
    add QWORD rcx, 3                                   ; offset to access alpha channel
second_loop:
    mov rdx, rbx
    mov byte [rcx + 4*rbx], 255                        ; set the alpha value to 255
    inc rbx
    cmp rbx, rax
    jl second_loop

    sub QWORD rcx, 3                                   ; restore the value of rcx

    ; Function epilogue
    mov eax, 0                  ; Return 0

    mov rsp, rbp ; Deallocate local variables
    pop rbp ; Restore the caller's base pointer value
    ret

update_nn:

    ; ; Call printf
    ; lea     rcx, [rel message]   ; First parameter for printf
    ; mov rdx, rax ; second parameter for printf
    ; call    printf