global run_network
global load_weights

section .data
align 8
stored_dense1_weights: incbin "./mnist_simple_layers/layer_1/weights.bin"
stored_dense1_bias: incbin "./mnist_simple_layers/layer_1/bias.bin"
stored_dense2_weights: incbin "./mnist_simple_layers/layer_2/weights.bin"
stored_dense2_bias: incbin "./mnist_simple_layers/layer_2/bias.bin"


section .text

%define MNIST_SIZE                      28
%define INPUT_SIZE                      MNIST_SIZE*MNIST_SIZE

%define DENSE1_SIZE                     128
%define DENSE1_BYTE_SIZE                4*DENSE1_SIZE
%define DENSE2_SIZE                     10
%define DENSE2_BYTE_SIZE                4*DENSE2_SIZE

%define DENSE1_WEIGHTS_BYTE_SIZE        INPUT_SIZE*DENSE1_SIZE*4
%define DENSE2_WEIGHTS_BYTE_SIZE        DENSE1_SIZE*DENSE2_SIZE*4


; void load_weights(int* dense1_weights, int* dense1_bias, int* dense2_weights, int* dense2_bias);
load_weights:
    ; Function prologue
    push    rbp
    mov     rbp, rsp
    sub     rsp, 32                                 ; Reserve 32 bytes of shadow space
    
    ; dense1_weights in rcx
    ; dense1_bias in rdx
    ; dense2_weights in r8
    ; dense2_bias in r9

    push rdi                                        ; callee-saved
    push rsi                                        ; callee-saved


    ; dense1 weights
    lea rsi, [rel stored_dense1_weights]            ; source
    mov rdi, rcx                                    ; destination
    mov rcx, DENSE1_WEIGHTS_BYTE_SIZE

    cld                                             ; clear direction flag (ensure forward copy)
    rep movsb                                       ; copy rcx bytes from [rsi] to [rdi]


    ; dense1 bias
    lea rsi, [rel stored_dense1_bias]               ; source
    mov rdi, rdx                                    ; destination
    mov rcx, DENSE1_BYTE_SIZE

    cld                                             ; clear direction flag (ensure forward copy)
    rep movsb                                       ; copy rcx bytes from [rsi] to [rdi]


    ; dense2 weights
    lea rsi, [rel stored_dense2_weights]            ; source
    mov rdi, r8                                     ; destination
    mov rcx, DENSE2_WEIGHTS_BYTE_SIZE

    cld                                             ; clear direction flag (ensure forward copy)
    rep movsb                                       ; copy rcx bytes from [rsi] to [rdi]


    ; dense2 bias
    lea rsi, [rel stored_dense2_bias]               ; source
    mov rdi, r9                                     ; destination
    mov rcx, DENSE2_BYTE_SIZE

    cld                                             ; clear direction flag (ensure forward copy)
    rep movsb                                       ; copy rcx bytes from [rsi] to [rdi]

    pop rsi
    pop rdi

    ; Function epilogue
    xor rax, rax                                    ; Return 0
    mov rsp, rbp                                    ; Deallocate local variables
    pop rbp                                         ; Restore the caller's base pointer value
    ret


; void run_network(uint8_t* input_buffer,
;                  int* dense1_weights, int* dense1_bias, int* dense2_weights, int* dense2_bias,
;                  int* output_buffer);
run_network:
    ; Function prologue
    push    rbp
    mov     rbp, rsp
    ; Reserve 32 bytes of shadow space + sizeof(int)*DENSE1_SIZE + sizeof(layer_1_output)
    %define reserved_space                          32 + DENSE1_BYTE_SIZE + 8
    sub     rsp, reserved_space                                 


    ; layer1_output
    mov r10, rbp
    sub r10, DENSE1_BYTE_SIZE
    sub r10, 8

    %define layer1_output                           rbp - 8
    mov [layer1_output], r10

    ; input_buffer in rcx
    ; dense1_weights in rdx
    ; dense1_bias in r8
    ; dense2_weights in r9
    
    ; dense2_bias on the stack
    ; output_buffer on the stack

    push r9

    ; ===============
    ; ==  layer 1  ==
    ; ===============

    xor rax, rax
    .loop:

    ; copy bias
    mov r9d, DWORD [r8 + 4*rax]
    mov r10, [layer1_output]
    mov DWORD [r10 + 4*rax], r9d

    xor r11, r11
    .inner_loop:

    ; layer1_output[row] += dense1_weights[row*INPUT_SIZE + i] * static_cast<int>(input_buffer[i]);
    mov r9d, INPUT_SIZE
    imul r9d, eax
    add r9d, r11d
    mov r9d, DWORD [rdx + 4*r9]

    movzx r10d, byte [rcx + r11]  ; zero-extend input_buffer byte to dword
    imul r9d, r10d

    mov r10, [layer1_output]
    add DWORD [r10 + 4*rax], r9d

    inc r11
    cmp r11, INPUT_SIZE
    jl .inner_loop

    inc rax
    cmp rax, DENSE1_SIZE
    jl .loop

    mov r10, [layer1_output]
    xor rax, rax
    .loop2:

    ; apply relu
    cmp DWORD [r10 + rax*4], DWORD 0
    jge .else
    mov DWORD [r10 + rax*4], DWORD 0
    jmp .endif
    .else:
    sar DWORD [r10 + rax*4], 8                      ; divide by 256

    .endif:
    inc rax
    cmp rax, DENSE1_SIZE
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


    ; ===============
    ; ==  layer 2  ==
    ; ===============

    mov rcx, [layer1_output]
    pop rdx                                         ; rdx now contains dense2_weights
    mov r8, [rbp + 48]                              ; r8 now contains dense2_bias
    mov r10, [rbp + 56]                             ; r10 now contains output_buffer

    xor rax, rax
    .loop3:

    ; copy bias
    mov r9d, DWORD [r8 + 4*rax]
    mov DWORD [r10 + 4*rax], r9d

    xor r11, r11
    .inner_loop2:

    ; output_buffer[row] += dense2_weights[row*DENSE1_SIZE + i] * layer1_output[i]; 
    mov r9, QWORD DENSE1_SIZE
    imul r9, rax
    add r9, r11
    mov r9d, DWORD [rdx + 4*r9]
    imul r9d, [rcx + 4*r11]

    add DWORD [r10 + 4*rax], r9d

    inc r11
    cmp r11, DENSE1_SIZE
    jl .inner_loop2

    inc rax
    cmp rax, DENSE2_SIZE
    jl .loop3

    ; Function epilogue
    xor rax, rax                                    ; Return 0
    mov rsp, rbp                                    ; Deallocate local variables
    pop rbp                                         ; Restore the caller's base pointer value
    ret
