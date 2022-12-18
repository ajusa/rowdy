import std/[strutils, parseutils, macros, genasts]
import mummy, mummy/routers, urlly

using req: Request
func params*(req): QueryParams =
  if req.httpMethod == "GET":
    req.uri.parseUrl.query
  else:
    req.body.parseUrl.query
proc fromRequest*(req; key: string; v: var SomeInteger) =
  if req.params[key].len != 0:
    v = req.params[key].parseInt
proc fromRequest*(req; key: string; v: var string) = v = req.params[key]
proc fromRequest*(req; key: string; v: var bool) = v = req.params[key].len != 0
proc fromRequest*[T: object](req; key: string; v: var T) =
  for name, value in v.fieldPairs:
    req.fromRequest(name, value)

proc fromRequest*[T: ref object](req; key: string; v: var T) =
  for name, value in v[].fieldPairs:
    req.fromRequest(name, value)

proc fromRequest*(req; key: string; v: var Request) = v = req

macro expandHandler*(request: Request; handler: proc): untyped =
  result = newStmtList()
  let
    pImpl = handler.getImpl()
    call = newCall(handler)
  for idef in pImpl.params[1..^1]:
    let name = idef[0]
    let newName = genSym(nskVar, "arg")
    call.add newName
    result.add:
      genast(request, newName, typ = idef[1], name):
        var newName: typ
        when compiles(new(newName)):
          new(newName)
        request.fromRequest(astToStr(name), newName)
  result.add:
    genast(request, call):
      # In case the handler doesn't return a string
      when compiles(request.respond(200, body = call)):
        request.respond(200, body = call)
      else:
        call

template autoRoute*(router: var Router; httpMethod: string; handler: proc) =
  block:
    proc mummyHandler(req) =
      req.expandHandler(handler)
    router.addRoute(httpMethod, "/" & astToStr(handler), mummyHandler)

template get*(router: var Router; handler: auto) = router.autoRoute("GET", handler)
template put*(router: var Router; handler: auto) = router.autoRoute("PUT", handler)
template delete*(router: var Router; handler: auto) = router.autoRoute("DELETE", handler)
template post*(router: var Router; handler: auto) = router.autoRoute("POST", handler)
