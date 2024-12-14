%include "constants.inc"
%include "http.inc"
%include "messages.inc"

global  init_server
global  accept_connection
global  close_connection
extern  error             ; Declare the error function

section .text

; ------------------------------------------------------------------------------
; Function: init_server
; Purpose : Creates and initializes a server socket for listening to connections
; Inputs  : None
; Outputs :
;   - rax: File descriptor of the created server socket (on success)
;   - rbx: Server socket file descriptor (internally saved)
; Returns : On error, calls the appropriate error handler and terminates
; Side Effects:
;   - Modifies rax, rbx, rdi, rsi, rdx, r8, r10
;   - Creates a socket, configures options, binds it to a port, and listens
; ------------------------------------------------------------------------------
init_server:
    ; Preserve caller-saved registers
    push rbx
    push rdi
    push rsi
    push rdx
    push r10

    ; ----- Create Socket -----
    mov  rax, SYS_SOCKET  ; syscall: socket(AF_INET, SOCK_STREAM, 0)
    mov  rdi, AF_INET     ; Address family: IPv4
    mov  rsi, SOCK_STREAM ; Type: TCP Stream socket
    xor  rdx, rdx         ; Protocol: 0 (default)
    syscall
    test rax, rax
    js   socket_error     ; Jump if creation failed

    ; Save socket file descriptor
    mov rbx, rax

    ; ----- Set SO_REUSEADDR Option -----
    mov  rax, SYS_SETSOCKOPT ; syscall: setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &optval, 4)
    mov  rdi, rbx            ; Socket FD (sockfd)
    mov  rsi, SOL_SOCKET     ; Level: Socket layer
    mov  rdx, SO_REUSEADDR   ; Option name: Reuse address (SO_REUSEADDR)
    lea  r10, [rel optval]   ; Address of option value (int 1)
    mov  r8,  4              ; Size of option value
    syscall
    test rax, rax
    js   setsockopt_error    ; Jump if failed

    ; ----- Bind the Socket -----
    mov     rdi, rbx            ; Socket FD
    mov     rax, SYS_BIND       ; syscall: bind(sockfd, &sockaddr, sizeof(sockaddr))
    lea     rsi, [rel sockaddr] ; &sockaddr
    mov     rdx, 16             ; sizeof(sockaddr)
    syscall                     ; bind(sockfd, &sockaddr, sizeof(sockaddr))
    test    rax, rax
    js      bind_error          ; Jump if failed

    ; ----- Start Listening -----
    mov  rdi, rbx        ; Socket FD
    mov  rax, SYS_LISTEN ; syscall: listen(sockfd, backlog)
    mov  rsi, 5          ; Backlog for pending connections
    syscall
    test rax, rax
    js   listen_error    ; Jump if failed

    ; Return the server socket file descriptor
    mov rax, rbx

    ; Restore preserved registers
    pop r10
    pop rdx
    pop rsi
    pop rdi
    pop rbx
    ret

; ------------------------------------------------------------------------------
; Function: accept_connection
; Purpose : Accepts a new client connection
; Inputs  :
;   - rdi: Server socket file descriptor
; Outputs :
;   - rax: Client socket file descriptor (on success)
; Returns : On error, calls accept_error and terminates
; Side Effects:
;   - Modifies rax
; ------------------------------------------------------------------------------
accept_connection:
    mov  rax, SYS_ACCEPT
    xor  rsi, rsi        ; Null sockaddr storage
    xor  rdx, rdx        ; Null sockaddr length storage
    syscall
    test rax, rax
    js   accept_error
    ret

; ------------------------------------------------------------------------------
; Function: close_connection
; Purpose : Closes a socket connection
; Inputs  :
;   - rdi: Socket file descriptor to close
; Outputs : None
; Returns : On error, calls close_error and terminates
; Side Effects:
;   - Modifies rax
; ------------------------------------------------------------------------------
close_connection:
    mov  rax, SYS_CLOSE ; prep to close the socket
    syscall        ; close the socket
    test rax, rax
    js   close_error
    ret

; ------------------------------------------------------------------------------
; Function: error
; Purpose : Prints an error message and exits
; Inputs  :
;   - rdi: Pointer to the error message string
;   - rsi: Length of the error message
; Outputs : None (writes to stderr)
; Side Effects:
;   - Terminates the program with exit code 1
; ------------------------------------------------------------------------------
error:
    mov rax, SYS_WRITE ; syscall: write(STDERR, message, length)
    mov rdi, 2         ; File descriptor: stderr
    syscall

    ; Exit with status code 1
    mov rax, SYS_EXIT ; syscall: exit(1)
    mov rdi, 1        ; Exit code 1
    syscall

; ----------------- Error Handlers -----------------
socket_error:
    lea  rdi, [rel MSG_SOCKET_CREATE_ERR]
    mov  rsi, MSG_SOCKET_CREATE_ERR_LEN
    call error

setsockopt_error:
    lea  rdi, [rel MSG_SETSOCKOPT_ERR]
    mov  rsi, MSG_SETSOCKOPT_ERR_LEN
    call error

bind_error:
    lea  rdi, [rel MSG_BIND_ERR]
    mov  rsi, MSG_BIND_ERR_LEN
    call error

listen_error:
    lea  rdi, [rel MSG_LISTEN_ERR]
    mov  rsi, MSG_LISTEN_ERR_LEN
    call error

accept_error:
    lea  rdi, [rel MSG_ACCEPT_ERR]
    mov  rsi, MSG_ACCEPT_ERR_LEN
    call error

close_error:
    lea  rdi, [rel MSG_CLOSE_ERR]
    mov  rsi, MSG_CLOSE_ERR_LEN
    call error

section .data
; --------- Socket Configuration Data ---------
sockaddr:
    dw AF_INET         ; sin_family: IPv4
    dw DEFAULT_PORT    ; sin_port: Port 8270 (0x4E20)
    dd 0               ; sin_addr: 0.0.0.0 (any interface)
    db 0,0,0,0,0,0,0,0 ; Padding for struct alignment

optval: dd 1 ; int optval = 1
