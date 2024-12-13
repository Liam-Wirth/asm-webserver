%include "constants.inc"
%include "http.inc"
%include "messages.inc"

global _start
global server_socket
extern init_server
extern accept_connection
extern close_connection
extern handle_request
extern setup_signal_handlers
extern error                 ; Declare the error function
extern log_info
extern log_error
extern log_debug

section .text

_start:
    ; Initialize server
    call setup_signal_handlers

    call init_server
    mov [server_socket], rax   ; Store the server socket FD

    lea rdi, [rel MSG_SERVER_START]
    mov rsi, MSG_SERVER_START_LEN
    call log_info

    syscall

request_loop:
    ; Log waiting for connection
    lea rdi, [rel MSG_WAITING_CONNECTION]
    mov rsi, MSG_WAITING_CONNECTION_LEN
    call log_debug

    ; Accept connection
    mov rdi, [server_socket]
    call accept_connection
    mov [client_socket], rax

    ; Log connection accepted
    lea rdi, [rel MSG_CONNECTION_ACCEPTED]
    mov rsi, MSG_CONNECTION_ACCEPTED_LEN
    call log_info

    ; Fork process
    mov rax, SYS_FORK
    syscall
    test rax, rax
    js fork_error               ; Check for fork error
    jz handle_child             ; Child process

    ; Parent process
    mov rdi, [client_socket]
    call close_connection
    jmp request_loop

handle_child:
    ; Handle the request in child process
    mov rdi, [client_socket]
    call handle_request

    ; Close connection
    mov rdi, [client_socket]
    call close_connection

    ; Exit child process
    xor rdi, rdi             ; Exit code 0
    mov rax, SYS_EXIT
    syscall

; Error Handlers
fork_error:
    lea rdi, [rel MSG_FORK_ERR]
    mov rsi, MSG_FORK_ERR_LEN
    call error

section .bss
server_socket: resq 1
client_socket: resq 1
