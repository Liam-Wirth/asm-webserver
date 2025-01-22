// re-implementing the webserver in PURE C!!! YAY!!!! NO STANDARD LIBRARIES!!!!

#define _GNU_SOURCE
#define STDIN_FILENO 0
#define STDOUT_FILENO 1
#define STDERR_FILENO 2

// System call numbers
#define SYS_WRITE 1
#define SYS_SOCKET 41
#define SYS_ACCEPT 43
#define SYS_BIND 49
#define SYS_LISTEN 50
#define SYS_SETSOCKOPT 54
#define SYS_EXIT 60

// Socket constants
#define AF_INET 2
#define SOCK_STREAM 1
#define SOL_SOCKET 1
#define SO_REUSEADDR 2
#define DEFAULT_PORT 8080

// Basic structures needed for networking
struct sockaddr_in {
  unsigned short sin_family;
  unsigned short sin_port;
  unsigned int sin_addr;
  unsigned char pad[8];
};

// C - Specific helper functions
long len(char *str);

long syscall(long callnum, ...);
// Modeled after my print subroutine found in core/util.asm

// util functions:

void print(char *str);
void log_info(char *str);
void log_error(char *str);
void log_debug(char *str);
/*void exit_with_error(char* str);*/

// Might be dead code though so watch out

// network functions:
int init_server();
int accept_connection(int server_fd);
void close_connection(int fd);

// Network error handling
void net_err(char *err_msg, int len);

// --------------------------------- MAIN ---------------------------------

int main(void) {
   print("Hello, World!\n");
}

// BUG: BROKEN!!!!! FUCK!!!! need to rewrite completely
long syscall(long callnum, ...) { 
  long ret;

  // Use pointer to access varargs
  long *args = &callnum + 1; // points to the first vararg

  // Up to six arguments:
  long arg1 = args[0];
  long arg2 = args[1];
  long arg3 = args[2];
  long arg4 = args[3];
  long arg5 = args[4];
  long arg6 = args[5];

  register long r10 __asm__("r10") = arg4;
  register long r8 __asm__("r8") = arg5;
  register long r9 __asm__("r9") = arg6;

  __asm__ volatile("syscall"
                   : "=a"(ret)
                   : "a"(callnum), // rax
                     "D"(arg1),    // rdi
                     "S"(arg2),    // rsi
                     "d"(arg3),    // rdx
                     "r"(r10),     // r10
                     "r"(r8),      // r8
                     "r"(r9)       // r9
                   : "rcx", "r11", "memory");

  return ret;
}

void print(char *str) {
    long n= len(str);
    const char *ptr = str;

    // Calculate the length of the string

    // Inline assembly for the write syscall (SYS_WRITE)
    __asm__ volatile(
        "movq $1, %%rax\n"         // SYS_WRITE syscall number
        "movq $1, %%rdi\n"         // STDOUT_FILENO (file descriptor)
        "movq %0, %%rsi\n"         // Pointer to the string
        "movq %1, %%rdx\n"         // Length of the string
        "syscall\n"                // Perform the syscall
        :
        : "r"(str), "r"(n)       // Input operands
        : "rax", "rdi", "rsi", "rdx", "rcx", "r11", "memory" // Clobbered registers
    );
}

// TODO: Maybe a macro for a lot of these functions now that I have the syscall
// worked out
//
long len(char *str) {
  long len = 0;
  while (*str != '\0') {
    str++;
    len++;
  }
  return len;
}
