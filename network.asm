extern printf

section .data
message db 'value is %d', 10, 0    ; 10 is newline, 0 is string terminator


section .text

; int relu(int x)
; x in rcx
; return adress in rbx
; output value stored in eax
; modifies rax, rcx, rbx

relu:
    mov eax, ecx
    and rcx, 0x80000000            ; 1 followed by 31 zeros
    imul eax, rcx                  ; if sign bit is set, multiply by 0 otherways by 1
    jmp rbx

