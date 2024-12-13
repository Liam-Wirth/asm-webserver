# Web Server Implementation Checklist

## 1. Core Network Setup
- [x] Create socket
- [x] Bind to port
- [x] Listen for connections
- [x] Accept connections
- [x] handle socket cleanup
- [x] signal handling for graceful shutdown

## Basic Request Handling
- [x] Parse HTTP methods (GET/POST)
- [x] Extract request path
- [x] Basic request logging
- [ ] Complete POST handling
- [ ] Parse query parameters
- [ ] Parse request headers


## Response Generation
- [x] Send basic HTTP status codes:
  - [x] 200 OK
  - [ ] 404 Not Found
  - [x] 403 Forbidden
  - [ ] 500 Server Error
- [x] Include some headers:
  - [x] Content-Type (basic)
  - [ ] Content-Length
  - [x] Connection
- [x] Send response body


## File Operations
- [x] Read static files
- [x] Basic directory structure (/www)
- [x] Default file (index.html)
- [ ] Handle file not found
- [ ] Complete MIME type detection
- [x] Basic directory security


## Essential Security
- [x] Validate request paths
- [x] Prevent directory traversal
- [x] Character validation
- [x] Path whitelist
- [x] Basic input validation

## Error Handling and Logging
- [x] Structured logging (INFO/ERROR/DEBUG)
- [x] Handle socket errors
- [x] Handle file system errors
- [x] Process forking errors
- [x] Connection handling errors

## Process Management
- [x] Fork for each connection
- [x] Child process cleanup
- [x] Parent process continuation
- [x] Signal handling


## Maybe Later:
- [ ]  Multiple concurrent connections
- [ ]  Keep-alive connections
- [ ]  Request/response compression
- [ ]  Virtual hosting
- [ ]  HTTPS support
