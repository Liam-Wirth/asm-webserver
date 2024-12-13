%include "constants.inc"
%include "http.inc"
%include "messages.inc"

global init_server
global accept_connection
global close_connection
extern error                 ; Declare the error function

section .text

; Function: init_server
; Creates and initializes a server socket
; Returns: Socket file descriptor in rax
init_server:
    ; Create socket
    mov rax, SYS_SOCKET
    mov rdi, AF_INET
    mov rsi, SOCK_STREAM
    xor rdx, rdx
    syscall
    test rax, rax
    js socket_error             ; If rax < 0, jump to error handler

    ; Save socket fd
    mov rbx, rax

    ; Set SO_REUSEADDR
    mov rax, SYS_SETSOCKOPT
    mov rdi, rbx                ; sockfd
    mov rsi, SOL_SOCKET         ; level
    mov rdx, SO_REUSEADDR      ; optname
    lea r10, [rel optval]       ; pointer to optval
    mov r8, 4                   ; optlen (sizeof(int))
    syscall
    test rax, rax
    js setsockopt_error         ; If rax < 0, jump to error handler

    ; Bind socket
    mov rdi, rbx
    mov rax, SYS_BIND
    lea rsi, [rel sockaddr]
    mov rdx, 16
    syscall
    test rax, rax
    js bind_error

    ; Listen
    mov rdi, rbx
    mov rax, SYS_LISTEN
    mov rsi, 5                 ; backlog = 5
    syscall
    test rax, rax
    js listen_error

    mov rax, rbx    ; Return socket fd
    ret

; Function: accept_connection
; Accepts a new connection on the server socket
; Input: rdi - server socket fd
; Returns: Client socket fd in rax
accept_connection:
    mov rax, SYS_ACCEPT
    xor rsi, rsi
    xor rdx, rdx
    syscall
    test rax, rax
    js accept_error
    ret

; Function: close_connection
; Closes a socket connection
; Input: rdi - socket fd to close
close_connection:
    mov rax, SYS_CLOSE
    syscall
    test rax, rax
    js close_error
    ret

; Function: error
; Prints an error message to stderr and exits
; Input: rdi - pointer to error message
;        rsi - length of error message
error:
    mov rax, SYS_WRITE
    mov rdi, 2              ; stderr
    ; rsi already contains the pointer to the message
    ; rdx already contains the length
    syscall

    ; Exit with status code 1
    mov rax, SYS_EXIT
    mov rdi, 1              ; exit code 1
    syscall


; Error Handlers
socket_error:
    lea rdi, [rel MSG_SOCKET_CREATE_ERR]
    mov rsi, MSG_SOCKET_CREATE_ERR_LEN
    call error

setsockopt_error:
    lea rdi, [rel MSG_SETSOCKOPT_ERR]
    mov rsi, MSG_SETSOCKOPT_ERR_LEN
    call error

bind_error:
    lea rdi, [rel MSG_BIND_ERR]
    mov rsi, MSG_BIND_ERR_LEN
    call error

listen_error:
    lea rdi, [rel MSG_LISTEN_ERR]
    mov rsi, MSG_LISTEN_ERR_LEN
    call error

accept_error:
    lea rdi, [rel MSG_ACCEPT_ERR]
    mov rsi, MSG_ACCEPT_ERR_LEN
    call error

close_error:
    lea rdi, [rel MSG_CLOSE_ERR]
    mov rsi, MSG_CLOSE_ERR_LEN
    call error

section .data
sockaddr:
    dw AF_INET              ; sin_family
    dw DEFAULT_PORT         ; sin_port (0x4E20 for port 20000)
    dd 0                    ; sin_addr (0.0.0.0)
    db 0,0,0,0,0,0,0,0     ; sin_zero padding

optval: dd 1                ; int optval = 1

