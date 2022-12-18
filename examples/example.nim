import mummy, mummy/routers, rowdy
import norm/[model, sqlite], sugar
type Post* = ref object of Model
  text*: string
let db = open(":memory:", "", "", "")
db.createTables(Post())
proc getPost(id: int, other: string): string =
  return $id & other
  # Post().dup(db.select("id = ?", id)).text
proc createPost(post: Post): string =
  {.cast(gcsafe).}: discard post.dup(db.insert)
  return "created"

proc otherThing(request: Request, id: int) =
  request.respond(200, body="other" & $id)

var router: Router
router.get(getPost)
router.post(createPost)
router.get(otherThing)
router.get("/") do (request: Request):
  request.respond(200, body = "the index")
let server = newServer(router)
echo "Serving on http://localhost:8080"
server.serve(Port(8080))
