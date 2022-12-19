# rowdy

A library for [mummy](https://github.com/guzba/mummy) that allows you to bind a
proc to the router, and automatically parse parameters into the proc arguments.

# Example

```nim
import mummy, mummy/routers, rowdy
proc getPost(id: int): string =
  "you requested a post with id " & $id

var router: Router
router.get(getPost)
router.get("/") do (request: Request):
  request.respond(200, body = "the index")
let server = newServer(router)
echo "Serving on http://localhost:8080"
server.serve(Port(8080))
```

At this point, if you visit http://localhost:8080/getPost?id=4 you should see
```
you requested a post with id 4
```


# API: rowdy

```nim
import rowdy
```

## **proc** params


```nim
func params(req: Request): QueryParams {.raises: [ValueError].}
```

## **proc** fromRequest


```nim
proc fromRequest(req: Request; k: string; v: var SomeInteger)
```

## **proc** fromRequest


```nim
proc fromRequest(req: Request; k: string; v: var SomeFloat)
```

## **proc** fromRequest


```nim
proc fromRequest(req: Request; k: string; v: var string) {.raises: [ValueError], tags: [].}
```

## **proc** fromRequest


```nim
proc fromRequest(req: Request; k: string; v: var bool) {.raises: [ValueError], tags: [].}
```

## **proc** fromRequest


```nim
proc fromRequest[T: object](req: Request; key: string; v: var T)
```

## **proc** fromRequest


```nim
proc fromRequest[T: ref object](req: Request; key: string; v: var T)
```

## **proc** fromRequest


```nim
proc fromRequest(req: Request; key: string; v: var Request)
```

## **template** map


```nim
template map(router: var Router; methud: string; handler: proc)
```

## **template** map


```nim
template map(router: var Router; methud, path: string; handler: proc)
```

## **template** get


```nim
template get(router: var Router; handler: proc)
```

## **template** put


```nim
template put(router: var Router; handler: proc)
```

## **template** delete


```nim
template delete(router: var Router; handler: proc)
```

## **template** post


```nim
template post(router: var Router; handler: proc)
```
