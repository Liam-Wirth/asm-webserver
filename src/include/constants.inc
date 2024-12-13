%define SYS_READ        0
%define SYS_WRITE       1
%define SYS_OPEN        2
%define SYS_CLOSE       3
%define SYS_SOCKET      41
%define SYS_BIND        49
%define SYS_LISTEN      50
%define SYS_ACCEPT      43
%define SYS_SETSOCKOPT  54
%define SYS_FORK        57
%define SYS_EXIT        60

%define STDOUT          1
%define STDERR          2

; Socket constants
%define AF_INET         2
%define SOCK_STREAM     1
%define SOL_SOCKET      1
%define SO_REUSEADDR    2

; File constants
%define O_RDONLY        0
%define O_WRONLY        1
%define O_CREAT         64

%define SYS_SIGACTION   13
%define SIGINT          2
%define SA_RESTORER     0x04000000
