
#--------------------------------- HTTP Utils --------------------------------- 
#Used to determin if a request path matches a specific pattern
macro curSlice(value: string): untyped =
    result = quote do:
        #Handle the case where the value contains multiple levels
        var val = `value`.split("/")

        var match = false
        var split = req.url.path.split("/")

        #Check if the value is a variable, if it is handle this seperatly
        when `value`.hasPathVarArgs():
            #Extract the path variable arguments as a sequence and then feed them into the macro to generate the runtime code
            split.genPathVarExtractors(parsePathVarArgs(`value`))

            if pathArgMatch:
                match = true

        if match:#Prevent the extra comparisons if the path variable match has already succeeded
            discard

        elif split.len > (curPath.len+1) and split[0..(curPath.len+1)].join("/") == `value`:
            match = true

        elif split.len > (curPath.len+1) and (split[curPath.len+1] == `value` or "/" & split[curPath.len+1] == `value`):
            match = true

        elif val.len > 1 and split.len > (curPath.len + val.len):#Handle multiple levels
            match = true
            for i in 1..<val.len:
                if split[curPath.len + i] != val[i] and split[curPath.len + i] != "/" & val[i] and "/" & split[curPath.len + i] != val[i]:
                    match = false
                    break           
        match

#Returns the remaining portion of the request path
macro remPath*(): untyped =
    result = quote do:
        req.url.path.split("/")[1..^1][curPath.len..^1].join("/")