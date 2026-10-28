"""Web derlemesini yerel ağda https ile yayınlar (iPhone Safari'de konum testi için).

Kullanım: python -u tool/serve_https.py build/web tool/certs
"""
import functools
import http.server
import ssl
import sys

root, certdir = sys.argv[1], sys.argv[2]
handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=root)
server = http.server.ThreadingHTTPServer(("0.0.0.0", 8080), handler)
ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
ctx.load_cert_chain(f"{certdir}/cert.pem", f"{certdir}/key.pem")
server.socket = ctx.wrap_socket(server.socket, server_side=True)
print("https://0.0.0.0:8080 hazir", flush=True)
server.serve_forever()
