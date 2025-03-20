
section .data

section .text


%define mnist_size 28
%define input_size mnist_size*mnist_size

%define dense1_size 128
%define dense1_byte_size 4*dense1_size
%define dense2_size 10

; void run_network(uint8_t* input_buffer,
;                  int* dense1_weights, int* dense1_bias, int* dense2_weights, int* dense2_bias,
;                  int* output_buffer);

run_network:
    ; Function prologue
    push    rbp
    mov     rbp, rsp
    ; Reserve 32 bytes of shadow space + sizeof(int)*dense1_size
    %define reserved_space dense1_size + 32
    sub     rsp, reserved_space                                 

    mov r10, rbp
    sub r10, dense1_byte_size

    ; input_buffer in rcx
    ; dense1_weights in rdx
    ; dense1_bias in r8
    ; dense2_weights in r9
    
    ; dense2_bias on the stack
    ; output_buffer on the stack

    push r9

    ; layer 1

    xor rax, rax
    .loop:

     ; copy bias
    mov r9d, DWORD PTR [r8 + 4*rax]  
    mov DWORD PTR [r10 + 4*rax], r9d

    xor r11, r11
    .inner_loop:

    ; layer1_output[row] += dense1_weights[row*input_size + i] * static_cast<int>(input_buffer[i]);
    mov r9d, input_size
    imul r9d, eax
    add r9d, r11d
    mov r9d, DWORD PTR [rdx + 4*r9]
    imul r9d, BYTE PTR [rcx + r11]

    add DWORD PTR [r10 + 4*rax], r9d

    inc r11
    cmp r11, input_size
    jl .inner_loop

    inc rax
    cmp rax, dense1_size
    jl .loop


    xor rax, rax
    .loop2:
    ; apply relu
    cmp [r10 + rax*4], 0
    jge .else:
    mov [r10 + rax*4], 0
    jmp .endif
    .else:
    ; divide by 256
    sar [r10 + rax*4], 8
    .endif:
    inc rax
    cmp rax, dense1_size
    jl .loop2


    ; layer 2

    pop rdx                        ; rdx now contains dense2_weights
    mov r8, [rbp + 8]              ; r8 now contains dense2_bias
    mov r10, [rbp + 16]            ; r10 now contains output_buffer

    xor rax, rax
    .loop3:

     ; copy bias
    mov r9d, DWORD PTR [r8 + 4*rax]
    mov DWORD PTR [r10 + 4*rax], r9d

    xor r11, r11
    .inner_loop2:

    ; output_buffer[row] += dense2_weights[row*dense1_size + i] * layer1_output[i]; 
    mov r9d, dense1_size
    imul r9d, eax
    add r9d, r11d
    mov r9d, DWORD PTR [rdx + 4*r9]
    imul r9d, BYTE PTR [rcx + r11]

    add DWORD PTR [r10 + 4*rax], r9d

    inc r11
    cmp r11, dense1_size
    jl .inner_loop2

    inc rax
    cmp rax, dense2_size
    jl .loop3

    ; Function epilogue
    xor rax, rax                  ; Return 0

    mov rsp, rbp ; Deallocate local variables
    pop rbp ; Restore the caller's base pointer value
    ret
