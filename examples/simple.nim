import mummy, mummy/routers, rowdy
proc getPost(id: int): string =
  "you requested a post with id " & $id

var router: Router
router.get(getPost)
router.autoRoute("GET", "/custom") do (q: string) -> string:
  "you searched for " & q
router.get("/") do (request: Request):
  request.respond(200, body = "the index")
let server = newServer(router)
echo "Serving on http://localhost:8080"
server.serve(Port(8080))