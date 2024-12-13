%include "constants.inc"
%include "http.inc"
%include "messages.inc"

section .text
global print
global log_info
global log_error
global log_debug


; Print Subroutine
; Arguments:
; rdi - Address of the string
; rsi - Length of the string
print:
    push rdi
    push rsi
    push rdx

    mov rdx, rsi    ; length
    mov rsi, rdi    ; message
    mov rdi, STDOUT ; file descriptor
    mov rax, SYS_WRITE
    syscall

    pop rdx
    pop rsi
    pop rdi
    ret

; Log Info message with timestamp
; Arguments:
; rdi - Address of the message
; rsi - Length of the message
log_info:
    push rdi
    push rsi

    ; Print timestamp and INFO prefix
    lea rdi, [rel log_info_prefix]
    mov rsi, log_info_prefix_len
    call print

    ; Print actual message
    pop rsi
    pop rdi
    call print

    ; Print newline
    lea rdi, [rel newline]
    mov rsi, 1
    call print
    ret

; Log Error message with timestamp
; Arguments:
; rdi - Address of the message
; rsi - Length of the message
log_error:
    push rdi
    push rsi

    ; Print timestamp and ERROR prefix
    lea rdi, [rel log_error_prefix]
    mov rsi, log_error_prefix_len
    call print

    ; Print actual message
    pop rsi
    pop rdi
    call print

    ; Print newline
    lea rdi, [rel newline]
    mov rsi, 1
    call print
    ret

; Log Debug message with timestamp
; Arguments:
; rdi - Address of the message
; rsi - Length of the message
log_debug:
    push rdi
    push rsi

    ; Print timestamp and DEBUG prefix
    lea rdi, [rel log_debug_prefix]
    mov rsi, log_debug_prefix_len
    call print

    ; Print actual message
    pop rsi
    pop rdi
    call print

    ; Print newline
    lea rdi, [rel newline]
    mov rsi, 1
    call print
    ret

section .data
log_info_prefix: db "[INFO] "
log_info_prefix_len equ $ - log_info_prefix

log_error_prefix: db "[ERROR] "
log_error_prefix_len equ $ - log_error_prefix

log_debug_prefix: db "[DEBUG] "
log_debug_prefix_len equ $ - log_debug_prefix

newline: db 10    ; newline character
