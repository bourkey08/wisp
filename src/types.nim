#------------------ Types for the HTTP server ------------------
type HTTPServerConfig* = object
    port*: uint16 = 8080
    address*: string = ""
    threads*: int = 1
    maxBody*: int = 1024*1024*5
    reusePort*: bool = false


type HTTPServer* = ref object
    httpServer*: AsyncHttpServer
    config*: HTTPServerConfig
