%include "constants.inc"
%include "messages.inc"

global  setup_signal_handlers
global  cleanup_and_exit

extern  server_socket         ; Defined in main.asm, stores server socket FD

section .text

; Source for how I wrote this file
; I asked chatgpt how computers handle segfaults/sigint and it gave me a "good enough" base to work off of and write this

; ------------------------------------------------------------------------------
; Function: setup_signal_handlers
; Purpose : Sets up the SIGINT (Ctrl+C) handler to ensure a graceful shutdown.
; Inputs  : None
; Outputs : None
; Returns : None (exits on error)
; Side Effects:
;   - Sets up a custom handler for SIGINT using the SYS_SIGACTION syscall.
; ------------------------------------------------------------------------------
setup_signal_handlers:
    ; Save the current base pointer
    push rbp
    mov  rbp, rsp

    ; ----- Configure sigaction Struct -----
    ; Assign the custom handler `cleanup_and_exit` to SIGINT
    mov QWORD [sigaction.handler],  cleanup_and_exit
    mov QWORD [sigaction.flags],    0                ; No special flags
    mov QWORD [sigaction.restorer], 0                ; Not used in modern Linux
    mov QWORD [sigaction.mask],     0                ; No additional signals blocked

    ; ----- Register the Signal Handler -----
    ; syscall: sigaction(SIGINT, &sigaction, NULL)
    mov     rax, SYS_SIGACTION ; System call number for sigaction
    mov     rdi, SIGINT        ; Signal: SIGINT (Ctrl+C)
    lea     rsi, [sigaction]   ; Address of sigaction struct
    xor     rdx, rdx           ; NULL old action pointer
    syscall                    ; Register the signal handler

    ; Restore the base pointer and return
    mov rsp, rbp
    pop rbp
    ret

; ------------------------------------------------------------------------------
; Function: cleanup_and_exit
; Purpose : Cleans up the server socket and terminates gracefully.
; Inputs  : None (uses global server_socket)
; Outputs : None
; Returns : Never (terminates the process)
; Side Effects:
;   - Prints a shutdown message
;   - Closes the server socket
;   - Terminates the process with exit code 0
; ------------------------------------------------------------------------------
cleanup_and_exit:
    ; ----- Print Cleanup Message -----
    ; syscall: write(STDOUT, "Server shutting down...", MSG_CLEANUP_LEN)
    mov rax, SYS_WRITE
    mov rdi, STDOUT            ; Write to standard output
    lea rsi, [rel MSG_CLEANUP] ; Message pointer
    mov rdx, MSG_CLEANUP_LEN   ; Message length
    syscall

    ; ----- Close Server Socket -----
    ; syscall: close(server_socket)
    mov rax, SYS_CLOSE
    mov rdi, [server_socket] ; Server socket FD from main.asm
    syscall

    ; ----- Terminate Process -----
    ; syscall: exit(0)
    mov rax, SYS_EXIT
    xor rdi, rdi      ; Exit code 0 (success)
    syscall

section .data

; ----- sigaction Struct for SIGINT Handler -----
sigaction:
    .handler:  dq 0 ; Pointer to cleanup_and_exit
    .flags:    dq 0 ; No special flags
    .restorer: dq 0 ; Unused 
    .mask:     dq 0 ; No signals masked
