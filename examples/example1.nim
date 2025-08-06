import std/[asyncdispatch, strformat]

import "../src/wisp.nim"

#Define the config to use for the server
let config = newWispConfig(8080, "127.0.0.1", 4, "10MB", true)

#Create a server instance using the config
let server = newWispServer(config)

routes "anotherHandler":
    get "/another":
        headers {"Content-type": "text/plain; charset=utf-8"}
        resp "This is another handler response."

#Define the handler for handling requests
let handler = router:
    get "/":
        headers {"Content-type": "text/html; charset=utf-8"}
        resp """
            <h1>Welcome to the Wisp Example Home Page</h1>
            <p>This is a basic home page served by your Nim Wisp server.</p>
        """

    get "/testing":
        headers {"Content-type": "text/plain; charset=utf-8"}
        resp "<div>hello</div>"

    addRoute anotherHandler

    #Set a default response in the case none of the routes match
    resp 404

#Start listening for requests
echo "Starting Wisp server on port ", config.port
waitFor server.start(handler)