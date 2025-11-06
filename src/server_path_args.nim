#------------------------------------------------------------------------------------------------------------------------------------------------------
#                                                                Implements path arguments
#------------------------------------------------------------------------------------------------------------------------------------------------------
type PathVarType = enum
    pathSeqString
    pathString
    pathInt
    pathUint
    pathInt8
    pathInt16
    pathInt32
    pathInt64
    pathUint8
    pathUint16
    pathUint32
    pathUint64
    pathFloat
    pathFloat32
    pathFloat64
    pathBool
    pathStatic#Used to represent a static path segment

type PathVarArgs = object
    name: string
    varType: PathVarType

#Takes the part of the path after the : and returns the corresponding PathVarType
func getArgType(typeStr: string): PathVarType {.compiletime.} = 
    case typeStr.toLower():
    of "seq[string]": return pathSeqString
    of "string": return pathString
    of "int": return pathInt
    of "uint": return pathUint
    of "int8": return pathInt8
    of "int16": return pathInt16
    of "int32": return pathInt32
    of "int64": return pathInt64
    of "uint8": return pathUint8
    of "uint16": return pathUint16
    of "uint32": return pathUint32
    of "uint64": return pathUint64
    of "float": return pathFloat
    of "float32": return pathFloat32
    of "float64": return pathFloat64
    of "bool": return pathBool
    else: return pathString

#Takes a path string and returns true/false indicating if the current level is a path argument
func isPathVarArg(path: string): bool {.compiletime.} =
    if not path.endsWith(">") and not path.endsWith(">/"):
        return false

    if path.startsWith("<"):
        return true

    elif path.startsWith("/<"):
        return true
    return false

#Works like the above but checks if a path contains ANY path variables rather than just a single path variable
func hasPathVarArgs(path: string): bool {.compiletime.} =
    for pathPart in path.split("/"):
        if isPathVarArg(pathPart):
            return true
    return false

#Takes a path string and returns the corresponding PathVarArgs object
func parsePathVarArg(path: string): PathVarArgs {.compiletime.} =
    var resp: PathVarArgs
    if ":" in path:
        #Get the variable name and type portion (stripping the <>)
        let startIdx = tern(path[0] == '<', 1, 2)
        let endIdx = tern(path[^1] == '>', 2, 3)

        let parts = path[startIdx..^(endIdx)].split(":")

        if parts.len != 2:
            throw "Invalid path variable argument format"

        #Set the name using the first 
        resp.name = parts[0]
        resp.varType = getArgType(parts[1])

    else:
        let startIdx = tern(path[0] == '<', 1, 2)
        let endIdx = tern(path[^1] == '>', 2, 3)

        resp.name = path[startIdx..^(endIdx)]
        resp.varType = pathString#If no type is specified then default to string

    return resp

#Takes the raw path string and split it up into individual path variable arguments
func parsePathVarArgs(path: string): seq[PathVarArgs] {.compiletime.} =
    var resp: seq[PathVarArgs] = @[]

    #Splits the path into the individual path variable arguments
    for pathPart in path.split("/"):
        if isPathVarArg(pathPart):
            resp.add(parsePathVarArg(pathPart))
        else:#Otherwise add the static path segment as is
            if pathPart != "":
                resp.add(PathVarArgs(name: pathPart, varType: pathStatic))
    return resp

#Takes a value and an argument defintion and generates the code to parse the argument into the correct format
macro genArgParser(arg: static PathVarArgs, val: seq[string], i: int) = 
    #Define the variable that will be used to store the passed variable
    var argName = newIdentNode(arg.name)

    case arg.varType:
    of pathString:
        result = quote do:
            var `argName`: string
            if `val`.len > `i`:
                `argName` = `val`[`i`]

    of pathInt:
        result = quote do:
            var `argName`: int
            if `val`.len > `i`:
                `argName` = parseInt(`val`[`i`])

    of pathUint:
        result = quote do:
            var `argName`: uint
            if `val`.len > `i`:
                `argName` = parseInt(`val`[`i`]).uint

    of pathInt8:
        result = quote do:
            var `argName`: int8
            if `val`.len > `i`:
                `argName` = parseInt(`val`[`i`]).int8

    of pathInt16:
        result = quote do:
            var `argName`: int16
            if `val`.len > `i`:
                `argName` = parseInt(`val`[`i`]).int16

    of pathInt32:
        result = quote do:
            var `argName`: int32
            if `val`.len > `i`:
                `argName` = parseInt(`val`[`i`]).int32

    of pathInt64:
        result = quote do:
            var `argName`: int64
            if `val`.len > `i`:
                `argName` = parseInt(`val`[`i`]).int64

    of pathUint8:
        result = quote do:
            var `argName`: uint8
            if `val`.len > `i`:
                `argName` = parseInt(`val`[`i`]).uint8

    of pathUint16:
        result = quote do:
            var `argName`: uint16
            if `val`.len > `i`:
                `argName` = parseInt(`val`[`i`]).uint16

    of pathUint32:
        result = quote do:
            var `argName`: uint32
            if `val`.len > `i`:
                `argName` = parseInt(`val`[`i`]).uint32

    of pathUint64:
        result = quote do:
            var `argName`: uint64
            if `val`.len > `i`:
                `argName` = parseInt(`val`[`i`]).uint64

    of pathFloat:
        result = quote do:
            var `argName`: float
            if `val`.len > `i`:
                `argName` = parseFloat(`val`[`i`])

    of pathFloat32:
        result = quote do:
            var `argName`: float32
            if `val`.len > `i`:
                `argName` = parseFloat(`val`[`i`]).float32

    of pathFloat64:
        result = quote do:
            var `argName`: float64
            if `val`.len > `i`:
                `argName` = parseFloat(`val`[`i`]).float64

    of pathBool:
        result = quote do:
            var `argName`: bool
            if `val`.len > `i`:
                `argName` = `val`[`i`] == "true" or `val`[`i`] == "1" or `val`[`i`] == "yes" or `val`[`i`] == "on"

    of pathSeqString:
        result = quote do:
            var `argName`: seq[string]
            if `val`.len > `i`:
                `argName` = `val`[`i`..^1]

    else:
        result = quote do: 
            var `argName`: string
            if `val`.len > `i`:
                `argName` = `val`[`i`]

#Generates the runtime code to extract path variables and make them available to the request handler
macro genPathVarExtractors(val: seq[string], vars: static seq[PathVarArgs]) =
    #Define the variable that will be "exported" to indicate if the path arguments matched
    let pathArgMatch = newIdentNode("pathArgMatch")
    let curPath = newIdentNode("curPath")    
    let tVal = newIdentNode("tVal")

    #If the 2 sequences are different lengths then they will never match so abort now
    var resp = newStmtList()
    resp = quote do:
        #Trim the path value to remove the portion that has already been matched by existing path entries in the tree
        #This needs to be done at runtime as the path here is the path provided by the users browser
        let `tVal` = `val`[`curPath`.len+1..^1]

        var `pathArgMatch` = true
        if `tVal`.len < `vars`.len:
            `pathArgMatch` = false

    for i in 0..<vars.len:
        #Handle static portions of the path seperatly
        if vars[i].varType == pathStatic:
            var pathPart = vars[i].name

            resp = quote do:
                `resp`
                if `tVal`.len <= `i`:
                    `pathArgMatch` = false

                elif `tVal`[`i`] != `pathPart`:
                    `pathArgMatch` = false
        else:
            var varName = newIdentNode(vars[i].name)

            resp = quote do:
                `resp`
                (`vars`[`i`]).genArgParser(`tVal`, `i`)

    return resp