
#--------------------------------- HTTP Verbs --------------------------------- 
macro get*(name: string, body: untyped): untyped =
    result = quote do:
        if req.reqMethod == HttpGet and curSlice(`name`):
            curPath.add(`name`)
            `body`

macro post*(name: string, body: untyped): untyped =
    result = quote do:
        if req.reqMethod == HttpPost and req.url.path.startsWith(`name`):
            curPath.add(`name`)
            `body`            

macro put*(name: string, body: untyped): untyped =
    result = quote do:
        if req.reqMethod == HttpPut and req.url.path.startsWith(`name`):
            curPath.add(`name`)
            `body`

macro patch*(name: string, body: untyped): untyped =
    result = quote do:
        if req.reqMethod == HttpPatch and req.url.path.startsWith(`name`):
            curPath.add(`name`)
            `body`

macro delete*(name: string, body: untyped): untyped =
    result = quote do:
        if req.reqMethod == HttpDelete and req.url.path.startsWith(`name`):
            curPath.add(`name`)
            `body`