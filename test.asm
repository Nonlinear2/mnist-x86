global initialize_device_context


extern CreateCompatibleDC
extern CreateDIBSection
extern SelectObject


%define bitmap_info_offset                      28

section .text
; void initialize_device_context(Buffer& buffer, int width, int height);
initialize_device_context:
    ; Function prologue
    push    rbp
    mov     rbp, rsp
    ; Reserve 32 bytes of shadow space + 8 bytes for local variables + 8 bytes for 16 byte alignement
    sub     rsp, 64

    ; buffer in rcx
    ; width in rdx
    ; height in r8

    %define buffer                              rbp + 2*8           ; rcx home

    mov QWORD [buffer], rcx

    ; =============================
    ; initialize buffer.bitmap_info
    ; =============================

    add rcx, bitmap_info_offset

    ; buffer.bitmap_info.bmiHeader.biSize = sizeof(buffer.bitmap_info.bmiHeader);
    ; bmiHeader offset is 0
    mov DWORD [rcx], 40             ; biSize offset is 0
    mov DWORD [rcx + 4], edx        ; biWidth offset is 4
    neg r8d
    mov DWORD [rcx + 8], r8d        ; biHeight offset is 8
    mov WORD [rcx + 12], 1          ; biPlanes offset is 12
    mov WORD [rcx + 14], 32         ; biBitCount offset is 14
    mov DWORD [rcx + 16], 0         ; biCompression offset is 16, value is BI_RGB

    ; Call CreateCompatibleDC(0)
    xor rcx, rcx                    ; single argument, 0
    call CreateCompatibleDC

    ; save DC to buffer.frame_device_context
    mov r10, [buffer]
    mov [r10 + 16], rax             ; frame_device_context offset is 16

    ; =====================
    ; call CreateDIBSection
    ; =====================

    sub rsp, 32 + 16                          ; 32 bytes of shadow space + 2 stack parameters, rsp is still 16 byte aligned
    mov rcx, 0                              ; NULL
    lea rdx, [r10 + bitmap_info_offset]     ; &buffer.bitmap_info
    xor r8, r8                              ; DIB_RGB_COLORS
    lea r9, [r10]                           ; &buffer.pixels, offset is 0
    mov QWORD [rsp + 4 * 8], 0
    mov QWORD [rsp + 5 * 8], 0
    call CreateDIBSection
    add rsp, 48                     ; clear the parameter space

    mov r10, [buffer]
    mov [r10 + 8], rax           ; bitmap offset is 8

    ; call SelectObject
    mov rcx, [r10 + 16]          ; frame_device_context offset is 16
    mov rdx, rax
    call SelectObject


    ; Function epilogue
    xor rax, rax                  ; Return 0

    mov rsp, rbp ; Deallocate local variables
    pop rbp ; Restore the caller's base pointer value
    ret