; Remove the .intel_syntax directive as NASM uses Intel syntax by default

; Replace .globl with global
global _start
%define BUFFER_SIZE 4096
%define SYS_READ 0
%define SYS_WRITE 1

; Replace .section with section
section .text

_start:
    mov rax, 41             ; syscall: syscall number 41
    mov rdi, 2              ; argument 1
    mov rsi, 1              ; argument 2
    xor rdx, rdx            ; argument 3
    syscall

    mov rbx, rax            ; Save return value

    mov rdi, rbx            ; Argument 1
    mov rax, 49             ; syscall number 49
    lea rsi, [rel sockaddr] ; Argument 2 with RIP-relative addressing
    mov rdx, 16             ; Argument 3
    syscall

    mov rdi, rbx            ; Argument 1
    mov rax, 50             ; syscall number 50
    mov rsi, 0              ; Argument 2
    syscall

request_loop:
    mov rdi, rbx            ; Argument 1
    xor rsi, rsi            ; Argument 2
    xor rdx, rdx            ; Argument 3
    mov rax, 43             ; syscall number 43
    syscall

    mov r12, rax            ; Save return value

    mov rax, 57             ; syscall number 57
    syscall

    test rax, rax
    jz handle_request

    mov rdi, r12            ; Argument 1
    mov rax, 3              ; syscall number 3
    syscall
    jmp request_loop

handle_request:
    push rbp
    mov rbp, rsp

    ; Save client fd
    mov r12, rdi

    ; Read request
    sub rsp, BUFFER_SIZE
    mov rdi, r12            ; Client socket fd
    mov rsi, rsp            ; Buffer
    mov rdx, BUFFER_SIZE    ; Buffer size
    mov rax, SYS_READ
    syscall
    mov r15, rax            ; Save request length

    ; Check if GET or POST
    mov al, 'P'
    cmp byte [rsp], al
    je handle_post
    jmp handle_get

handle_get:
    ; Get filename (after GET)
    mov rdi, rsp
    add rdi, 4               ; Skip "GET "
    mov r14, rdi             ; Save start of path

    ; Find end of path
    mov rcx, r15
    mov al, ' '
    repne scasb
    dec rdi
    mov byte [rdi], 0        ; Null terminate path

    ; Open file for reading
    mov rax, 2               ; syscall number 2 (open)
    mov rdi, r14             ; Filename
    xor rsi, rsi             ; O_RDONLY
    syscall

    mov r14, rax             ; Save file descriptor

    ; Read file
    mov rdi, r14             ; File descriptor
    sub rsp, 4096
    mov rsi, rsp             ; Buffer
    mov rdx, 4096            ; Count
    xor rax, rax             ; syscall number 0 (read)
    syscall
    mov r13, rax             ; Save bytes read

    ; Close file
    mov rdi, r14             ; File descriptor
    mov rax, 3               ; syscall number 3 (close)
    syscall

    ; Send response headers
    mov rdi, r12             ; Argument 1
    lea rsi, [rel http_response] ; Argument 2 with RIP-relative addressing
    mov rdx, 19              ; Length
    mov rax, 1               ; syscall number 1 (write)
    syscall

    ; Send file contents
    mov rdi, r12             ; Argument 1
    mov rsi, rsp             ; Buffer
    mov rdx, r13             ; Length
    mov rax, 1               ; syscall number 1 (write)
    syscall
    jmp request_done

handle_post:
    ; Get filename (after POST)
    mov rdi, rsp
    add rdi, 5               ; Skip "POST "
    mov r14, rdi             ; Save start of path

    ; Find end of path
    mov rcx, r15
    mov al, ' '
    repne scasb
    dec rdi
    mov byte [rdi], 0        ; Null terminate path

    ; Find double CRLF
    mov rdi, rsp
    mov rcx, r15
find_body:
    cmp dword [rdi], 0x0a0d0a0d
    je found_body
    inc rdi
    loop find_body
found_body:
    add rdi, 4               ; Skip \r\n\r\n
    mov r13, rdi             ; Save start of body

    ; Open file
    mov rax, 2               ; syscall number 2 (open)
    mov rdi, r14             ; Filename
    mov rsi, 65              ; O_WRONLY | O_CREAT
    mov rdx, 0777            ; Permissions
    syscall

    mov r14, rax             ; Save file descriptor

    ; Write POST data
    mov rdi, r14             ; File descriptor
    mov rsi, r13             ; POST data
    mov rdx, r15             ; Total length
    add rdx, rsp             ; Adjust for stack base
    sub rdx, r13             ; Subtract header length
    mov rax, 1               ; syscall number 1 (write)
    syscall

    ; Close file
    mov rdi, r14             ; File descriptor
    mov rax, 3               ; syscall number 3 (close)
    syscall

    ; Send response
    mov rdi, r12             ; Argument 1
    lea rsi, [rel http_response] ; Argument 2 with RIP-relative addressing
    mov rdx, 19              ; Length
    mov rax, 1               ; syscall number 1 (write)
    syscall

request_done:
    ; Exit
    xor rdi, rdi             ; Status 0
    mov rax, 60              ; syscall number 60 (exit)
    syscall

section .data
sockaddr:
    dw 2                    ; AF_INET
    dw ; Port number (20,000 in little endian)
    dd 0                    ; IP address (0.0.0.0)
    dq 0                    ; Padding or additional data

http_response:
    db "HTTP/1.0 200 OK\r\n\r\n", 0

