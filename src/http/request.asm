%include "constants.inc"
%include "http.inc"
%include "messages.inc"

global handle_request
global handle_get
global handle_post

extern error
extern print
extern log_info
extern log_error
extern log_debug

section .text

; Function: handle_request
; Input: rdi - client socket fd
handle_request:
    push rbp
    mov rbp, rsp
    mov r12, rdi            ; Store client FD in r12

    lea rdi, [rel MSG_REQUEST_RECEIVED]
    mov rsi, MSG_REQUEST_RECEIVED_LEN
    call log_info

    ; Read request
    sub rsp, BUFFER_SIZE
    mov rdi, r12            ; fd = client socket
    mov rsi, rsp            ; buffer
    mov rdx, BUFFER_SIZE
    mov rax, SYS_READ
    syscall
    test rax, rax
    js read_error
    mov r15, rax            ; request length

    ; log details of request
    mov rdi, rsp
    mov rsi, r15
    call log_debug

    ; Check if GET or POST
    mov al, 'P'
    cmp byte [rsp], al
    je handle_post
    jmp handle_get

; Function: validate_path
; Input: rdi - pointer to path
; Output: rax - 0 if path is invalid, 1 if valid
validate_path:
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi

    mov rbx, rdi        ; Store original path pointer

    ; Check for whitelisted paths first
    mov rsi, whitelist_paths
.check_whitelist:
    mov rdi, rbx            ; Original path
    mov rcx, rsi            ; Current whitelist entry
.whitelist_loop:
    mov al, byte [rdi]
    mov dl, byte [rcx]
    test dl, dl
    jz .whitelist_match     ; End of whitelist entry = match
    test al, al
    jz .whitelist_next      ; End of path = no match
    cmp al, dl
    jne .whitelist_next
    inc rdi
    inc rcx
    jmp .whitelist_loop

.whitelist_next:
    ; Move to next whitelist entry
    mov rcx, rsi
.find_next:
    cmp byte [rcx], 0
    jz .found_next
    inc rcx
    jmp .find_next
.found_next:
    inc rcx                 ; Skip null terminator
    mov rsi, rcx
    cmp byte [rsi], 0      ; Check if at end of whitelist
    jz .continue_validation
    jmp .check_whitelist

.whitelist_match:
    mov rax, 1             ; Path is whitelisted
    jmp .cleanup

.continue_validation:
    ; First check: bad characters
    mov rdx, rbx        ; Current position in path
.check_bad_chars:
    movzx eax, byte [rdx]
    test al, al
    jz .check_delims

    ; Check against bad_chars
    mov rsi, bad_chars
.bad_char_loop:
    movzx ecx, byte [rsi]
    test cl, cl
    jz .next_char

    cmp al, cl
    je .invalid_path

    inc rsi
    jmp .bad_char_loop

.next_char:
    inc rdx
    jmp .check_bad_chars

.check_delims:
    ; Second check: count dots and slashes
    xor ecx, ecx            ; dot counter
    xor edx, edx            ; slash counter
    mov rsi, rbx

.count_loop:
    movzx eax, byte [rsi]
    test al, al
    jz .check_counts

    cmp al, '.'
    jne .check_slash
    inc ecx
    jmp .continue_count

.check_slash:
    cmp al, '/'
    jne .continue_count
    inc edx

.continue_count:
    inc rsi
    jmp .count_loop

.check_counts:
    cmp ecx, 2
    jge .invalid_path

    cmp edx, 2
    jge .invalid_path

    mov rax, 1
    jmp .cleanup

.invalid_path:
    xor rax, rax

.cleanup:
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

; Function: handle_get
handle_get:
    lea rdi, [rel MSG_HANDLING_GET]
    mov rsi, MSG_HANDLING_GET_LEN
    call log_info

    ; Get filename (after "GET ")
    mov rdi, rsp
    add rdi, 4
    mov r14, rdi

    ; Print path for debugging
    lea rdi, [rel MSG_REQUEST_RECEIVED]
    mov rsi, MSG_REQUEST_RECEIVED_LEN
    call print

    ; validate the path
    mov rdi, r14
    call validate_path
    test rax, rax
    jz .send_security_response

    ; If path is "/", use "index.html"
    cmp byte [r14], '/'
    jne .use_path
    cmp byte [r14 + 1], ' '
    jne .use_path
    lea r14, [rel default_file]
    jmp .prepare_path

.send_security_response:
    lea rdi, [rel MSG_SECURITY_VIOLATION]
    mov rsi, MSG_SECURITY_VIOLATION_LEN
    call log_error

    ; Send 403 response headers
    mov rdi, r12
    lea rsi, [rel security_response]
    mov rdx, security_response_len
    mov rax, SYS_WRITE
    syscall
    test rax, rax
    js write_error

    lea r14, [rel security_file]
    jmp .prepare_path

.use_path:
    ; Find end of path
    mov rcx, r15
    mov al, ' '
    repne scasb
    dec rdi
    mov byte [rdi], 0
    add r14, 1

.prepare_path:
    ; Prepare full file path
    lea rdi, [rel file_path]
    mov rsi, r14
    call concat_path

.open_file:
    mov rax, SYS_OPEN
    lea rdi, [rel file_path]
    mov rsi, O_RDONLY
    mov rdx, 0644o
    syscall
    test rax, rax
    js open_error
    mov r14, rax

    ; Send response headers
    mov rdi, r12
    lea rsi, [rel http_response]
    mov rdx, http_response_len
    mov rax, SYS_WRITE
    syscall
    test rax, rax
    js write_error

    ; Read and send file in chunks
.read_loop:
    mov rdi, r14
    sub rsp, BUFFER_SIZE
    mov rsi, rsp
    mov rdx, BUFFER_SIZE
    mov rax, SYS_READ
    syscall
    test rax, rax
    jle .read_done
    mov r13, rax

    ; Send chunk
    mov rdi, r12
    mov rsi, rsp
    mov rdx, r13
    mov rax, SYS_WRITE
    syscall
    test rax, rax
    js write_error

    add rsp, BUFFER_SIZE
    jmp .read_loop

.read_done:
    mov rdi, r14
    mov rax, SYS_CLOSE
    syscall
    jmp request_done

; Function to concatenate www_dir with file path
concat_path:
    push rdi
    push rsi

    lea rsi, [rel www_dir]
    .copy_dir:
        lodsb
        test al, al
        jz .copy_file
        stosb
        jmp .copy_dir

    .copy_file:
        pop rsi
        push rsi
    .copy_loop:
        lodsb
        stosb
        test al, al
        jnz .copy_loop

    pop rsi
    pop rdi
    ret

handle_post:
    lea rdi, [rel MSG_REQUEST_RECEIVED]
    mov rsi, MSG_REQUEST_RECEIVED_LEN
    call print
    jmp request_done

; Error handlers
read_error:
    lea rdi, [rel MSG_READ_ERR]
    mov rsi, MSG_READ_ERR_LEN
    call log_error
    jmp done

open_error:
    lea rdi, [rel MSG_OPEN_ERR]
    mov rsi, MSG_OPEN_ERR_LEN
    call log_error
    jmp done

write_error:
    lea rdi, [rel MSG_WRITE_ERR]
    mov rsi, MSG_WRITE_ERR_LEN
    call log_error
    jmp done

request_done:
    leave
    ret

done:
    leave
    ret

section .data
www_dir: db "./www/", 0
default_file: db "index.html", 0
security_file: db "nope.html", 0

whitelist_paths:
    db "/favicon.ico", 0
    db "/index.html", 0
    db "/", 0
    db 0                    ; End of whitelist

http_response:
    db "HTTP/1.1 200 OK", 13, 10
    db "Content-Type: text/html", 13, 10
    db "Connection: close", 13, 10
    db 13, 10
http_response_len equ $ - http_response

security_response:
    db "HTTP/1.1 403 Forbidden", 13, 10
    db "Content-Type: text/html", 13, 10
    db "Connection: close", 13, 10
    db 13, 10
security_response_len equ $ - security_response

; only allowed one . and one /
path_delims: db 0x2E, 0, 0x2F, 0, 0

; \:*?"<>|
bad_chars: db 0x5C, 0x3A, 0x2A, 0x3F, 0x25, 0x22, 0x3C, 0x3E, 0x7C, 0

section .bss
file_path: resb 256         ; Buffer for full file path
