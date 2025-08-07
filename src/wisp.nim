#------------------------------------------------------------------------------------------------------------------------------------------------------
#                Implements a wrapper around the standard library AsyncHttpServer to provide an interface inspired by python flask library
#------------------------------------------------------------------------------------------------------------------------------------------------------

#Enable experimental features that are used
{.experimental: "codeReordering".}

import std/[macros, asynchttpserver, asyncdispatch, net, strutils, tables, options, cgi]
import std/macrocache

#Include std nim macros
include "external/nim_macros/blib.nim"

include "./types.nim"
include "./server_verbs.nim"
include "./server_utils.nim"
include "./server_resp.nim"

#Used to store routes as ast to prevent them being evaluated out of scope
const routesTbl = CacheTable"routes"
const mcCounter = CacheCounter"myCounter"

proc newWispConfig*(port: auto, address: string = "", threads: int = 1, maxBody: string = "5MB", reusePort: bool=false): HTTPServerConfig =
    when port is string:
        let portNum = parseInt(port)
    else:
        let portNum = port

    result = HTTPServerConfig(
        port: uint16 portNum,
        address: address,
        threads: threads,
        maxBody: parseBinaryUnits(maxBody),
        reusePort: reusePort
    )

#Define a constructor for the http server type
proc newWispServer*(config: HTTPServerConfig = HTTPServerConfig()): HttpServer =
    result = HTTPServer(
        httpServer: newAsyncHttpServer(),
        config: config
    )

macro router*(routerBody: untyped): untyped =
    var req = newIdentNode("req")
    var curPath = newIdentNode("curPath")
    var path = newIdentNode("path")
    var body = newIdentNode("body")
    var query = newIdentNode("query")

    when defined(release):
        result = quote do:
            proc (`req`: Request) {.async.} =
                try:
                    #Define variables that are used for internal state
                    var `curPath`: seq[string] = @[]

                    #Unpack the query string into an ordered table
                    var `query`: OrderedTable[string, string] = initOrderedTable[string, string]()
                    for entry in decodeData(`req`.url.query):
                        `query`[entry.key] = entry.value
                        
                    #Set some variables that should be available to handler functions
                    var `path` = `req`.url.path
                    var `body` = `req`.body

                    `routerBody`
                except:
                    discard
    else:
        result = quote do:
            proc (`req`: Request) {.async.} =
                #Define variables that are used for internal state
                var `curPath`: seq[string] = @[]

                #Unpack the query string into an ordered table
                var `query`: OrderedTable[string, string] = initOrderedTable[string, string]()
                for entry in decodeData(`req`.url.query):
                    `query`[entry.key] = entry.value
                    
                #Set some variables that should be available to handler functions
                var `path` = `req`.url.path
                var `body` = `req`.body

                `routerBody`

#Allows defining additional routes in a seperate function/file
macro routes*(name: static string, routesBody: untyped): untyped =
    var req = newIdentNode("req")
    var curPath = newIdentNode("curPath")
    var path = newIdentNode("path")
    var body = newIdentNode("body")
    var query = newIdentNode("query")
    var funcName = newIdentNode(name)

    result = quote do:
        proc `funcName`(`req`: Request, passPath: seq[string], `path`: string, `body`: string, `query`: OrderedTable[string, string]) {.async.} =
            var `curPath` = passPath  
            `routesBody`

#Works the same as the routes macro but the route is scoped to the parent
macro routesInline*(name: static string, routesBody: untyped): untyped =
    routesTbl[name] = routesBody 
    mcCounter.inc()

#Called to include additional routes in the routing table for the server
macro addRoute*(routeBody: untyped): untyped =
    var req = newIdentNode("req")
    var curPath = newIdentNode("curPath")
    var path = newIdentNode("path")
    var body = newIdentNode("body")
    var query = newIdentNode("query")

    result = quote do:
        await `routeBody`(`req`, `curPath`, `path`, `body`, `query`)

macro addRoute*(routeName: static string): untyped =
    let entry = routesTbl[routeName]
    result = quote do:
        `entry`

proc start*(self: HTTPServer, cb: proc) {.async.} =   
    #Bind to the HTTP port and address specified in the settings
    if self.config.address == "":
        self.httpServer.listen(Port(self.config.port))
    else:
        self.httpServer.listen(Port(self.config.port), self.config.address)

    while true:
        if self.httpServer.shouldAcceptRequest():
            await self.httpServer.acceptRequest(cb)
        else:
            # too many concurrent connections, `maxFDs` exceeded
            # wait 10ms to allow for some connections to close
            await sleepAsync(10)