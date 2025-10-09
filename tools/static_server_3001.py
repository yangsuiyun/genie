import http.server, socketserver, os, gzip, io
from urllib.parse import unquote

ROOT = "/home/suiyun/claude/genie/mobile/build/web"
CACHE_LONG = "public, max-age=31536000, immutable"
CACHE_HTML = "no-cache"

class GzipCachingHandler(http.server.SimpleHTTPRequestHandler):
    def translate_path(self, path):
        path = unquote(path.split("?",1)[0])
        newpath = ROOT
        for part in path.strip("/").split("/"):
            if part in (os.curdir, os.pardir):
                continue
            newpath = os.path.join(newpath, part)
        return newpath

    def end_headers(self):
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("X-Frame-Options", "SAMEORIGIN")
        self.send_header("Referrer-Policy", "no-referrer-when-downgrade")
        self.send_header("Permissions-Policy", "geolocation=(),microphone=(),camera=()")
        super().end_headers()

    def send_head(self):
        path = self.translate_path(self.path)
        if os.path.isdir(path):
            path = os.path.join(path, "index.html")
        ctype = self.guess_type(path)
        try:
            f = open(path, "rb")
        except OSError:
            self.send_error(404, "File not found")
            return None
        fs = os.fstat(f.fileno())
        cache = CACHE_HTML if path.endswith("index.html") else CACHE_LONG
        use_gzip = False
        ae = self.headers.get("Accept-Encoding") or ""
        if (ctype.startswith("text/") or ctype in ("application/javascript","application/json")) or path.endswith(".js"):
            if fs.st_size > 1024 and "gzip" in ae:
                use_gzip = True
        self.send_response(200)
        self.send_header("Content-type", ctype)
        self.send_header("Cache-Control", cache)
        self.send_header("Last-Modified", self.date_time_string(fs.st_mtime))
        data = f.read()
        f.close()
        if use_gzip:
            buf = io.BytesIO()
            with gzip.GzipFile(fileobj=buf, mode="wb", compresslevel=5) as gz:
                gz.write(data)
            gz_data = buf.getvalue()
            self.send_header("Content-Encoding", "gzip")
            self.send_header("Content-Length", str(len(gz_data)))
            self.end_headers()
            return io.BytesIO(gz_data)
        else:
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            return io.BytesIO(data)

if __name__ == "__main__":
    os.chdir(ROOT)
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", "3001"))
    with socketserver.TCPServer((host, port), GzipCachingHandler) as httpd:
        print(f"Serving at http://{host}:{port}")
        httpd.serve_forever()
