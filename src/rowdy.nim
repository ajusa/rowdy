import std/[strutils, parseutils, macros, genasts]
import mummy, mummy/routers, webby
export mummy, routers

func params*(req: Request): QueryParams =
  if req.httpMethod == "GET":
    req.uri[req.uri.rfind("?") + 1 .. ^1].parseSearch
  else:
    req.body.parseSearch

proc fromRequest*(req: Request; k: string; v: var SomeInteger) =
  if k in req.params:
    v = req.params[k].parseInt

proc fromRequest*(req: Request; k: string; v: var SomeFloat) =
  if k in req.params:
    v = req.params[k].parseFloat
proc fromRequest*(req: Request; k: string; v: var string) = v = req.params[k]
proc fromRequest*(req: Request; k: string; v: var bool) = v = k in req.params
proc fromRequest*[T: object](req: Request; key: string; v: var T) =
  for name, value in v.fieldPairs:
    req.fromRequest(name, value)
proc fromRequest*[T: ref object](req: Request; key: string; v: var T) =
  for name, value in v[].fieldPairs:
    req.fromRequest(name, value)

proc fromRequest*(req: Request; key: string; v: var Request) = v = req

macro expandHandler(request: Request; handler: proc): untyped =
  result = newStmtList()
  var pImpl: NimNode
  if handler.kind == nnkLambda:
    pImpl = handler
  else:
    pImpl = handler.getImpl()
  let call = newCall(handler)
  for idef in pImpl.params[1..^1]:
    let name = idef[0]
    let newName = genSym(nskVar, "arg")
    var typ: NimNode
    if idef[1].kind == nnkVarTy:
      typ = idef[1][0]
    else:
      typ = idef[1]
    call.add newName
    result.add:
      genast(request, newName, typ, name):
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

template map*(router: var Router; methud: string; handler: proc) =
  mixin expandHandler
  block:
    proc mummyHandler(request: Request) =
      request.expandHandler(handler)
    router.addRoute(methud, "/" & astToStr(handler), mummyHandler)

template map*(router: var Router; methud, path: string; handler: proc) =
  mixin expandHandler
  block:
    proc mummyHandler(request: Request) =
      request.expandHandler(handler)
    router.addRoute(methud, path, mummyHandler)

template get*(router: var Router; handler: proc) = router.map("GET", handler)
template put*(router: var Router; handler: proc) = router.map("PUT", handler)
template delete*(router: var Router; handler: proc) = router.map("DELETE", handler)
template post*(router: var Router; handler: proc) = router.map("POST", handler)