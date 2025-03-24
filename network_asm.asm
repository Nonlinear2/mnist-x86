global run_network

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
    ; Reserve 32 bytes of shadow space + sizeof(int)*dense1_size + sizeof(layer_1_output)
    %define reserved_space dense1_byte_size + 32 + 8
    sub     rsp, reserved_space                                 


    ; layer1_output
    mov r10, rbp
    sub r10, dense1_byte_size
    sub r10, 8

    %define layer1_output [rbp - 8]
    mov layer1_output, r10

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
    mov r9d, DWORD [r8 + 4*rax]
    mov r10, layer1_output
    mov DWORD [r10 + 4*rax], r9d

    xor r11, r11
    .inner_loop:

    ; layer1_output[row] += dense1_weights[row*input_size + i] * static_cast<int>(input_buffer[i]);
    mov r9d, input_size
    imul r9d, eax
    add r9d, r11d
    mov r9d, DWORD [rdx + 4*r9]

    movzx r10d, byte [rcx + r11]  ; zero-extend input_buffer byte to dword
    imul r9d, r10d

    mov r10, layer1_output
    add DWORD [r10 + 4*rax], r9d

    inc r11
    cmp r11, input_size
    jl .inner_loop

    inc rax
    cmp rax, dense1_size
    jl .loop

    mov r10, layer1_output
    xor rax, rax
    .loop2:
    ; apply relu
    cmp DWORD [r10 + rax*4], DWORD 0
    jge .else
    mov DWORD [r10 + rax*4], DWORD 0
    jmp .endif
    .else:
    ; divide by 256
    sar DWORD [r10 + rax*4], 8
    .endif:
    inc rax
    cmp rax, dense1_size
    jl .loop2



    ; ┌─────────────┐                    
    ; │top of stack │◄──── rsp   ▲       
    ; ├─────────────┤            │       
    ; │    ....     │            │       
    ; ├─────────────┤            │stack  
    ; │  saved rbp  │◄──── rbp   │growth
    ; ├─────────────┤            │       
    ; │return adress│            │       
    ; ├─────────────┤            │       
    ; │   rcx home  │                    
    ; ├─────────────┤                    
    ; │   rdx home  │                    
    ; ├─────────────┤                    
    ; │   r8 home   │                    
    ; ├─────────────┤            │       
    ; │   r9 home   │ rbp+40     │       
    ; ├─────────────┤            │ high  
    ; │ parameter 1 │ rbp+48     │ adress
    ; ├─────────────┤            │       
    ; │ parameter 2 │            │       
    ; ├─────────────┤            │       
    ; │    ....     │            ▼       
    ; └─────────────┘                    

    ; layer 2
    mov rcx, layer1_output
    pop rdx                        ; rdx now contains dense2_weights
    mov r8, [rbp + 48]             ; r8 now contains dense2_bias
    mov r10, [rbp + 56]            ; r10 now contains output_buffer

    xor rax, rax
    .loop3:

    ; copy bias
    mov r9d, DWORD [r8 + 4*rax]
    mov DWORD [r10 + 4*rax], r9d

    xor r11, r11
    .inner_loop2:

    ; output_buffer[row] += dense2_weights[row*dense1_size + i] * layer1_output[i]; 
    mov r9, QWORD dense1_size
    imul r9, rax
    add r9, r11
    mov r9d, DWORD [rdx + 4*r9]
    imul r9d, [rcx + 4*r11]

    add DWORD [r10 + 4*rax], r9d

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
