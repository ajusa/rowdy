import typetraits, strutils, parseutils, sequtils, mummy/routers, mummy, urlly

proc args*(declaration: typedesc[proc]): seq[string] =
  captureBetween(declaration.name, '(', ')').split(", ").mapIt(it.split(": ")[0])

using req: Request
func query*(req): QueryParams = 
  if req.httpMethod == "GET":
    req.uri.parseUrl.query
  else:
    req.body.parseUrl.query
proc fromRequest*(req; key: string, v: var SomeInteger) = 
  if req.query[key].len != 0:
    v = req.query[key].parseInt
proc fromRequest*(req; key: string, v: var string) = v = req.query[key]
proc fromRequest*(req; key: string, v: var bool) = v = req.query[key].len != 0
proc fromRequest*[T: object](req; key: string, v: var T) = 
  for name, value in v.fieldPairs:
    echo name, value
    req.fromRequest(name, value)

proc fromRequest*[T: ref object](req; key: string, v: var T) = 
  for name, value in v[].fieldPairs:
    echo name, value
    req.fromRequest(name, value)

proc fromRequest*(req; key: string, v: var Request) = v = req

template autoRoute[T1](router: var Router, httpMethod: string, handler: proc(arg1: T1): string) =
  block:
    proc mummyHandler(request: Request) =
      var arg1: T1
      when compiles(new(arg1)):
        new(arg1)
      # when compiles(request.fromRequest(handler.type.args[0], arg1)):
      request.fromRequest(handler.type.args[0], arg1)
      let response = handler(arg1)
      request.respond(200, body = response)
    router.addRoute(httpMethod, "/" & astToStr(handler), mummyHandler)

template autoRoute[T1, T2](router: var Router, httpMethod: string, handler: proc(arg1: T1, arg2: T2): string) =
  block:
    proc mummyHandler(request: Request) =
      var arg1: T1
      when compiles(request.fromRequest(handler.type.args[0], arg1)):
        request.fromRequest(handler.type.args[0], arg1)
      var arg2: T2
      when compiles(request.fromRequest(handler.type.args[0], arg2)):
        request.fromRequest(handler.type.args[0], arg2)
      let response = handler(arg1, arg2)
      request.respond(200, body = response)
    router.addRoute(httpMethod, "/" & astToStr(handler), mummyHandler)

# const httpMethod = path[0..<path.find({'A'..'Z'})].toUpperAscii

template get*(router: var Router, handler: auto) = router.autoRoute("GET", handler)
template put*(router: var Router, handler: auto) = router.autoRoute("PUT", handler)
template delete*(router: var Router, handler: auto) = router.autoRoute("DELETE", handler)
template post*(router: var Router, handler: auto) = router.autoRoute("POST", handler)