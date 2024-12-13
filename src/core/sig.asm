%include "constants.inc"
%include "messages.inc"

global setup_signal_handlers
global cleanup_and_exit

extern server_socket    ; From main.asm

section .text

; Function: setup_signal_handlers
; Sets up handlers for signals like SIGINT (Ctrl+C)
setup_signal_handlers:
    push rbp
    mov rbp, rsp

    ; Setup sigaction struct
    mov QWORD [sigaction.handler], cleanup_and_exit
    mov QWORD [sigaction.flags], 0          ; no special flags
    mov QWORD [sigaction.restorer], 0
    mov QWORD [sigaction.mask], 0

    ; Install SIGINT handler
    mov rax, SYS_SIGACTION
    mov rdi, SIGINT
    lea rsi, [sigaction]
    xor rdx, rdx
    syscall

    mov rsp, rbp
    pop rbp
    ret

; Function: cleanup_and_exit
; Cleans up resources and exits gracefully
cleanup_and_exit:
    ; Print cleanup message
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [rel MSG_CLEANUP]
    mov rdx, MSG_CLEANUP_LEN
    syscall

    ; Close server socket
    mov rax, SYS_CLOSE
    mov rdi, [server_socket]
    syscall

    ; Exit normally
    mov rax, SYS_EXIT
    xor rdi, rdi     ; Exit code 0
    syscall

section .data
; Simplified sigaction structure
sigaction:
    .handler:    dq 0    ; sa_handler
    .flags:      dq 0    ; sa_flags
    .restorer:   dq 0    ; sa_restorer
    .mask:       dq 0    ; sa_mask

