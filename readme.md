# Web Server Implementation Checklist

## 1. Core Network Setup
- [x] Create socket
- [x] Bind to port
- [x] Listen for connections
- [x] Accept connections

## 2. Basic Request Handling
- [x] Parse HTTP methods (GET/POST)
- [ ] Extract request path
- [ ] Validate request format
- [ ] Parse basic headers

## 3. Response Generation
- [ ] Send proper HTTP status codes:
  - 200 OK
  - 404 Not Found
  - 500 Server Error
- [ ] Include essential headers:
  - Content-Type
  - Content-Length
  - Connection
- [ ] Send response body

## 4. File Operations
- [x] Read static files
- [ ] Handle file not found
- [ ] Basic MIME type detection
- [ ] Directory security

## 5. Essential Security
- [ ] Validate request paths
- [ ] Prevent directory traversal (`../`)
- [ ] Basic input validation
- [ ] Request size limits

## 6. Basic Error Handling
- [ ] Handle invalid requests
- [ ] Handle file system errors
- [ ] Return appropriate error pages
- [ ] Basic error logging

## Optional Advanced Features
- [ ] Multiple concurrent connections
- [ ] Keep-alive connections
- [ ] Request/response compression
- [ ] Virtual hosting
- [ ] HTTPS support
