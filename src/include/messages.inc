%include "http.inc"

section .rodata

	; Success Messages

MSG_SERVER_START:
	db                       "Server started on port 8270 \n you can visit it here: http://localhost:8270", 10
	MSG_SERVER_START_LEN equ $ - MSG_SERVER_START

	; Error Messages

MSG_SOCKET_CREATE_ERR:
	db                            "Error: Failed to create socket", 10
	MSG_SOCKET_CREATE_ERR_LEN equ $ - MSG_SOCKET_CREATE_ERR

MSG_SETSOCKOPT_ERR:
	db                         "Error: Failed to set SO_REUSEADDR", 10
	MSG_SETSOCKOPT_ERR_LEN equ $ - MSG_SETSOCKOPT_ERR

MSG_BIND_ERR:
	db                   "Error: Failed to bind socket", 10
	MSG_BIND_ERR_LEN equ $ - MSG_BIND_ERR

MSG_LISTEN_ERR:
	db                     "Error: Failed to listen on socket", 10
	MSG_LISTEN_ERR_LEN equ $ - MSG_LISTEN_ERR

MSG_ACCEPT_ERR:
	db                     "Error: Failed to accept connection", 10
	MSG_ACCEPT_ERR_LEN equ $ - MSG_ACCEPT_ERR

MSG_FORK_ERR:
	db                   "Error: Failed to fork process", 10
	MSG_FORK_ERR_LEN equ $ - MSG_FORK_ERR

MSG_READ_ERR:
	db                   "Error: Failed to read from socket", 10
	MSG_READ_ERR_LEN equ $ - MSG_READ_ERR

MSG_WRITE_ERR:
	db                    "Error: Failed to write to socket", 10
	MSG_WRITE_ERR_LEN equ $ - MSG_WRITE_ERR

MSG_OPEN_ERR:
	db                   "Error: Failed to open file", 10
	MSG_OPEN_ERR_LEN equ $ - MSG_OPEN_ERR

MSG_CLOSE_ERR:
	db                    "Error: Failed to close socket", 10
	MSG_CLOSE_ERR_LEN equ $ - MSG_CLOSE_ERR

MSG_404_ERR:
	db                  "Error: 404 Not Found", 10
	MSG_404_ERR_LEN equ $ - MSG_404_ERR

MSG_BUF_OVERFLOW:
	db                       "Shiii, buffer overflow :("
	MSG_BUF_OVERFLOW_LEN equ $ - MSG_BUF_OVERFLOW
	; Status Messages

MSG_REQUEST_RECEIVED:
	db                           "Request Received", 10
	MSG_REQUEST_RECEIVED_LEN equ $ - MSG_REQUEST_RECEIVED

MSG_HANDLING_REQUEST:
	db                           "Handling Request", 10
	MSG_HANDLING_REQUEST_LEN equ $ - MSG_HANDLING_REQUEST

MSG_CLEANUP:
	db                  "Server shutting down...", 10
	MSG_CLEANUP_LEN equ $ - MSG_CLEANUP

MSG_HANDLING_GET:
	db                       "Handling GET request"
	MSG_HANDLING_GET_LEN equ $ - MSG_HANDLING_GET

MSG_HANDLING_POST:
	db                        "Handling POST request"
	MSG_HANDLING_POST_LEN equ $ - MSG_HANDLING_POST

MSG_FILE_OPENED:
	db                      "File opened successfully"
	MSG_FILE_OPENED_LEN equ $ - MSG_FILE_OPENED

MSG_RESPONSE_SENT:
	db                        "Response sent successfully"
	MSG_RESPONSE_SENT_LEN equ $ - MSG_RESPONSE_SENT

MSG_WAITING_CONNECTION:
	db                             "Waiting for connection..."
	MSG_WAITING_CONNECTION_LEN equ $ - MSG_WAITING_CONNECTION

MSG_CONNECTION_ACCEPTED:
	db                              "New connection accepted"
	MSG_CONNECTION_ACCEPTED_LEN equ $ - MSG_CONNECTION_ACCEPTED

MSG_SECURITY_VIOLATION:
	db                             "security violation: attempted path traversal or invalid characters detected"
	MSG_SECURITY_VIOLATION_LEN equ $ - MSG_SECURITY_VIOLATION

MSG_500_ERR:
	db                  "500 Error Detected"
	MSG_500_ERR_LEN equ $ - MSG_500_ERR
