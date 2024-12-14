%include "constants.inc"
%include "http.inc"
%include "messages.inc"

global  send_response
global  send_security_response
global  send_404_response
global  concat_path
global  get_content_type

extern  log_error
extern  log_info

section .text

; ------------------------------------------------------------------------------
; Function: send_response
; Purpose : Sends an HTTP response containing a requested file
; Inputs  :
;   - rdi: Client socket file descriptor
;   - rsi: Pointer to the requested file path
; Outputs : None
; Returns : On success, sends the file content to the client.
;           On error, logs the issue and returns to the caller.
; Side Effects:
;   - Modifies rax, r12, r13, r14, rsi, rdi, rsp
; ------------------------------------------------------------------------------
send_response:
    ; Preserve caller-saved registers
    push r12
    push r13
    push r14

    ; ----- Store File Path and Client FD -----
    mov r12, rdi ; Save client socket FD
    mov r14, rsi ; Save file path pointer

    ; ----- Prepare Full File Path -----
    lea  rdi, [rel file_path] ; Destination buffer
    mov  rsi, r14             ; Source file path
    call concat_path          ; Combine paths into file_path

    ; ----- Open Requested File -----
    mov  rax, SYS_OPEN
    lea  rdi, [rel file_path] ; File to open
    mov  rsi, O_RDONLY        ; Read-only
    mov  rdx, 0644o           ; Permissions (ignored)
    syscall
    test rax, rax
    js   open_error           ; Jump if failed
    mov  r14, rax             ; Store file descriptor

    ; ----- Send HTTP Response Headers -----
    mov  rdi, r12
    lea  rsi, [rel http_response]
    mov  rdx, http_response_len
    mov  rax, SYS_WRITE
    syscall
    test rax, rax
    js   write_error              ; Jump if failed

    ; ----- Send File Content in Chunks -----
.read_loop:
    sub  rsp, BUFFER_SIZE
    mov  rdi, r14         ; File descriptor
    mov  rsi, rsp         ; Read buffer
    mov  rdx, BUFFER_SIZE ; Max bytes to read
    mov  rax, SYS_READ
    syscall
    test rax, rax
    jle  .read_done       ; Stop if done or failed
    mov  r13, rax         ; Store bytes read

    ; Send the chunk
    mov  rdi, r12       ; Client socket
    mov  rsi, rsp       ; Send buffer
    mov  rdx, r13       ; Bytes to send
    mov  rax, SYS_WRITE
    syscall
    test rax, rax
    js   write_error

    add rsp, BUFFER_SIZE
    jmp .read_loop

.read_done:
    ; Close the file after sending all content
    mov rdi, r14
    mov rax, SYS_CLOSE
    syscall

    ; Restore preserved registers
    pop r14
    pop r13
    pop r12
    ret

; ------------------------------------------------------------------------------
; Function: send_security_response
; Purpose : Sends a 403 Forbidden response with a default security file
; Inputs  :
;   - rdi: Client socket file descriptor
; Outputs : None
; Returns : On success, sends the response to the client.
;           On error, logs the issue and returns to the caller.
; Side Effects:
;   - Modifies rax, rsi, rdx, rdi
; ------------------------------------------------------------------------------
send_security_response:
    ; Log security violation
    lea  rdi, [rel MSG_SECURITY_VIOLATION]
    mov  rsi, MSG_SECURITY_VIOLATION_LEN
    call log_error

    ; Send 403 Response Headers
    mov  rdi, rdi                     ; Client socket FD
    lea  rsi, [rel security_response]
    mov  rdx, security_response_len
    mov  rax, SYS_WRITE
    syscall
    test rax, rax
    js   write_error                  ; Jump if failed

    ; Send Security File
    mov  rsi, security_file
    call send_response
    ret

; ------------------------------------------------------------------------------
; Function: concat_path
; Purpose : Concatenates the web directory with the requested file path
; Inputs  :
;   - rdi: Destination buffer for the concatenated path
;   - rsi: Source file path to append
; Outputs : None
; Returns : None
; Side Effects:
;   - Modifies rdi, rsi, al
; ------------------------------------------------------------------------------
concat_path:
    push rdi
    push rsi

    ; Copy www_dir into destination buffer
    lea rsi, [rel www_dir]
.copy_dir:
    lodsb
    test al, al
    jz   .copy_file
    stosb
    jmp  .copy_dir

.copy_file:
    pop  rsi
    push rsi
.copy_loop:
    lodsb
    stosb
    test al, al
    jnz  .copy_loop

    pop rsi
    pop rdi
    ret

; ----------------- Error Handlers -----------------
open_error:
    lea  rdi, [rel MSG_OPEN_ERR]
    mov  rsi, MSG_OPEN_ERR_LEN
    call log_error
    xor  rax, rax      ; Return 0 to indicate failure
    pop  r14
    pop  r13
    pop  r12
    ret



write_error:
    lea  rdi, [rel MSG_WRITE_ERR]
    mov  rsi, MSG_WRITE_ERR_LEN
    call log_error
    jmp  done

done:
    ret


; Function to check file extension and send appropriate headers
; Input: rdi - filename pointer
; Returns: rsi - pointer to appropriate response headers
;         rdx - length of headers
get_content_type:
    push rdi
    
    ; Find end of string
.find_end:
    cmp byte [rdi], 0
    je  .check_default
    inc rdi
    jmp .find_end

.check_ico:
    lea  rsi, [rel favicon_ext]
    call string_ends_with
    test rax, rax
    jz   .check_default
    
    lea rsi, [rel favicon_response]
    mov rdx, favicon_response_len
    jmp .done

.check_default:
    lea rsi, [rel http_response] ; Default to HTML
    mov rdx, http_response_len

.done:
    pop rdi
    ret

; Helper function: string_ends_with
; Input: rdi - string to check
;        rsi - extension to check for
; Output: rax - 1 if matches, 0 if not
string_ends_with:
    push rdi
    push rsi
    
    ; Find end of both strings
    mov rcx, rdi
.find_main_end:
    cmp byte [rcx], 0
    je  .found_main_end
    inc rcx
    jmp .find_main_end
.found_main_end:

    mov rdx, rsi
.find_ext_end:
    cmp byte [rdx], 0
    je  .found_ext_end
    inc rdx
    jmp .find_ext_end
.found_ext_end:

    ; Compare backwards
.compare_loop:
    dec rcx
    dec rdx
    cmp rdx, rsi
    jl  .match    ; Reached start of extension = match
    cmp rcx, rdi
    jl  .no_match ; Reached start of main string = no match
    
    movzx rax, byte [rcx]
    cmp   al,  byte [rdx]
    jne   .no_match
    jmp   .compare_loop

.match:
    mov rax, 1
    jmp .done

.no_match:
    xor rax, rax

.done:
    pop rsi
    pop rdi
    ret

;-------------------------------------------------------------------------------
; Function: send_404_response
; Purpose : Sends a 404 Not Found response with a default 404 page
; Inputs  :
; Outputs :
; Returns :
; Side Effects:
;-------------------------------------------------------------------------------
send_404_response:
    push rbp
    mov rbp, rsp
    push r12   ; Save registers if needed
    push r13
    push r14

    mov r12, rdi ; Save client socket fd

    ; Log 404 error
    lea rdi, [rel MSG_404_ERR]
    mov rsi, MSG_404_ERR_LEN
    call log_error

    ; Send 404 headers
    mov rdi, r12
    lea rsi, [rel not_found_response]
    mov rdx, not_found_response_len
    mov rax, SYS_WRITE
    syscall
    test rax, rax
    js .write_error

    mov rdi, r12             ; Client socket FD
    mov rsi, not_found_file  ; "404.html"
    call send_response       ; This will handle the file reading and sending

    mov rax, 1               ; Return success
    jmp .cleanup

.write_error:
    xor rax, rax ; Return failure

.cleanup:
    pop r14
    pop r13
    pop r12
    leave
    ret





section .data

; ----- File Path Configuration -----
www_dir:        db "./www/", 0
security_file:  db "nope.html", 0
not_found_file: db "404.html", 0

favicon_ext:    db ".ico", 0
html_ext:       db ".html", 0
css_ext:        db ".css", 0
js_ext:         db ".js", 0

; ----- HTTP Response Messages -----
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

favicon_response:
    db "HTTP/1.1 200 OK", 13, 10
    db "Content-Type: image/x-icon", 13, 10
    db "Connection: close", 13, 10
    db 13, 10
favicon_response_len equ $ - favicon_response

not_found_response:
    db "HTTP/1.1 404 Not Found", 13, 10
    db "Content-Type: text/html", 13, 10
    db "Connection: close", 13, 10
    db 13, 10
not_found_response_len equ $ - not_found_response

section    .bss
file_path: resb 256 ; Buffer for full file path