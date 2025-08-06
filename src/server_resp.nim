#--------------------------------- HTTP responses --------------------------------- 
macro headers*(body: untyped): untyped =
    var respHeaders = ident("respHeaders")
    result = quote do:
        when declared(`respHeaders`):
            `respHeaders` = `body`.newHttpHeaders()
        else:
            var `respHeaders` = `body`.newHttpHeaders()

macro resp*(body: string): untyped =
    result = quote do:
        when declared(respHeaders):
            await req.respond(Http200, `body`, respHeaders)
        else:
            await req.respond(Http200, `body`)

macro resp*(status: int, body: string): untyped =
    result = quote do:
        when declared(respHeaders):
            await req.respond(HttpCode(`status`), `body`, respHeaders)
        else:
            await req.respond(HttpCode(`status`), `body`)

macro resp*(status: int): untyped =
    result = quote do:
        when declared(respHeaders):
            await req.respond(HttpCode(`status`), "", respHeaders)
        else:
            await req.respond(HttpCode(`status`), "")

macro fresp*(body: string): untyped =
    result = quote do:
        when declared(respHeaders):
            req.respond(Http200, `body`, respHeaders)
        else:
            req.respond(Http200, `body`)

macro fresp*(status: int, body: string): untyped =
    result = quote do:
        when declared(respHeaders):
            req.respond(HttpCode(`status`), `body`, respHeaders)
        else:
            req.respond(HttpCode(`status`), `body`)

macro fresp*(status: int): untyped =
    result = quote do:
        when declared(respHeaders):
            req.respond(HttpCode(`status`), "", respHeaders)
        else:
            req.respond(HttpCode(`status`), "")