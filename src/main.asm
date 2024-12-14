%include "constants.inc"
%include "http.inc"
%include "messages.inc"

global  _start
global  server_socket
extern  init_server
extern  accept_connection
extern  close_connection
extern  handle_request
extern  setup_signal_handlers
extern  error                 ; Logs an error and terminates
extern  log_info              ; Logs informational messages
extern  log_error             ; Logs error messages
extern  log_debug             ; Logs debug messages

section .text

; ------------------------------------------------------------------------------
; Entry Point: _start
; Purpose : Server entry point, sets up the socket and enters request loop
; Inputs  : None
; Outputs : None (runs indefinitely or until a fatal error occurs)
; Side Effects:
;   - Calls functions that modify multiple registers (saved where needed).
;   - Creates, binds, and listens on a server socket.
; ------------------------------------------------------------------------------
_start:
    ; ----- Set Up Signal Handlers -----
    ; Sets up the SIGINT handler to allow graceful shutdown on Ctrl+C
    ; This prevents the server from leaving sockets open after termination.
    call setup_signal_handlers

    ; ----- Initialize Server Socket -----
    ; Calls init_server, which:
    ; - Creates a socket
    ; - Sets the SO_REUSEADDR option
    ; - Binds the socket to a port and listens for connections
    call init_server
    mov  [server_socket], rax ; Store server socket FD in memory

    ; Log that the server has successfully started
    lea  rdi, [rel MSG_SERVER_START]
    mov  rsi, MSG_SERVER_START_LEN
    call log_info

    ; Begin the main server request loop
request_loop:
    ; ----- Log Waiting for Connection -----
    ; Informational log showing the server is ready to accept new clients
    lea  rdi, [rel MSG_WAITING_CONNECTION]
    mov  rsi, MSG_WAITING_CONNECTION_LEN
    call log_debug

    ; ----- Accept New Client Connection -----
    ; Accept an incoming connection and store the client socket FD
    mov  rdi,             [server_socket] ; Pass server socket FD to accept_connection
    call accept_connection
    mov  [client_socket], rax             ; Store the client socket FD

    ; Log that the connection was successfully accepted
    lea  rdi, [rel MSG_CONNECTION_ACCEPTED]
    mov  rsi, MSG_CONNECTION_ACCEPTED_LEN
    call log_info

    ; ----- Fork a Child Process -----
    ; Create a new child process using SYS_FORK
    ; - Child process handles the client request
    ; - Parent process continues the request loop
    mov  rax, SYS_FORK
    syscall
    test rax, rax
    js   fork_error    ; Jump if fork failed
    jz   handle_child  ; Jump if in the child process (rax == 0)

    ; ----- Parent Process -----
    ; Close the client socket in the parent process and return to waiting
    mov  rdi, [client_socket]
    call close_connection
    jmp  request_loop

; ------------------------------------------------------------------------------
; Function: handle_child
; Purpose : Handles the client request in the child process
; Inputs  : None (client_socket already in memory)
; Outputs : None (terminates the process after handling the request)
; Side Effects:
;   - Processes the request and closes the client socket
; ------------------------------------------------------------------------------
handle_child:
    ; Handle the client request using the client socket FD
    mov  rdi, [client_socket]
    call handle_request

    ; Close the client connection after processing the request
    mov  rdi, [client_socket]
    call close_connection

    ; Terminate the child process
    xor rdi, rdi      ; Exit code 0 (normal exit)
    mov rax, SYS_EXIT
    syscall

; ------------------------------------------------------------------------------
; Error Handlers
; Purpose : Log errors and terminate the process if a failure occurs
; ------------------------------------------------------------------------------
fork_error:
    ; Log a fork failure and terminate the process
    lea  rdi, [rel MSG_FORK_ERR]
    mov  rsi, MSG_FORK_ERR_LEN
    call error

section        .bss
; Global Variables:
; server_socket : Stores the server's listening socket file descriptor
; client_socket : Stores the file descriptor for the current client connection
server_socket: resq 1
client_socket: resq 1
