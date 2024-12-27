PATH_TRAVERSAL_ATTEMPTS = [
    "../../../etc/passwd",
    "../../../../etc/shadow",
    "../../.ssh/id_rsa",
    "%2e%2e%2f%2e%2e%2f%2e%2e%2fetc%2fpasswd",
    "..%2F..%2F..%2Fetc%2Fpasswd",
    "....//....//....//etc/passwd",
    "../../../Windows/win.ini",
    "..\\..\\..\\Windows\\win.ini",
    "../../../../../../../../../../etc/passwd",
    "/etc/passwd",
    "file:///etc/passwd",
]

MALICIOUS_PATHS = [
    "/admin",
    "/.git/config",
    "/.env",
    "/wp-admin",
    "/phpinfo.php",
    "/api/v1/users",
    "/.htaccess",
    "/backup.sql",
    "/wp-config.php",
    "/config.php",
    "/admin.php",
    "/.svn/entries",
    "/.DS_Store",
    "/robots.txt",
    "/composer.json",
    "/package.json",
]

SPECIAL_CHARS = [
    "/*",
    "/?",
    "/#",
    "/%00",
    "/%0A",
    "/%0D",
    "/%20",
    "/%25",
    "/;",
    "/\\",
    "/&&",
    "/||",
    "/;",
    "/|",
    "/<script>",
    "/'",
    '/"',
    "/`",
    "/$(",
    "/${",
]

VALID_PAGES = ['', 'index.html', '404.html', 'nope.html']

RESULT_GROUPS = {
    'Valid Pages': VALID_PAGES,
    'Path Traversal': PATH_TRAVERSAL_ATTEMPTS,
    'Malicious Paths': MALICIOUS_PATHS,
    'Special Characters': SPECIAL_CHARS,
    'Random Paths': []  # Will be populated dynamically
}

