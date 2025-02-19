extern printf

section .data
message db 'value is %d', 10, 0    ; 10 is newline, 0 is string terminator


section .text

relu:
    ; rcx contains x
    ; output value stored in eax
    mov eax, ecx
    and rcx, 0x80000000            ; 1 followed by 31 zeros
    imul eax, rcx                  ; if sign bit is set, multiply by 0 otherways by 1
