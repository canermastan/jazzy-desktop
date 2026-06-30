import std/[json, macros, os, asyncdispatch, tables, strutils]
import jazzy
import jazzy/core/middlewares as jmw
import webview_ffi

export jazzy
export webview_ffi
export tables, strutils

# ─── EXPOSE MACRO ───────────────────────────────────────────────────────────────
# Generates a Jazzy HTTP POST route at /rpc/<funcName> for each annotated proc.
# The JS client sends: POST /rpc/funcName { "args": [...] }
# The handler parses args by position and returns { "result": <value> }

macro expose*(prc: untyped): untyped =
  prc.expectKind(nnkProcDef)
  let procName = prc[0]
  let procNameStr = $procName
  let params = prc[3]

  let wrapperName = genSym(nskProc, "handler_" & procNameStr)

  var extractStmts = newStmtList()
  var callArgs = newSeq[NimNode]()
  var argIdx = 0
  let argsIdent = ident("args")
  let ctxIdent = ident("ctx")

  for i in 1 ..< params.len:
    let paramDefs = params[i]
    let paramType = paramDefs[^2]

    for j in 0 ..< paramDefs.len - 2:
      let paramName = paramDefs[j]
      let typeStr = $paramType

      if typeStr == "Context":
        callArgs.add(ctxIdent)
      else:
        let extractStmt = case typeStr:
          of "string":
            quote do:
              let `paramName` = `argsIdent`[`argIdx`].getStr()
          of "int":
            quote do:
              let `paramName` = `argsIdent`[`argIdx`].getInt()
          of "float":
            quote do:
              let `paramName` = `argsIdent`[`argIdx`].getFloat()
          of "bool":
            quote do:
              let `paramName` = `argsIdent`[`argIdx`].getBool()
          else:
            quote do:
              let `paramName` = to(`argsIdent`[`argIdx`], `paramType`)

        extractStmts.add(extractStmt)
        callArgs.add(paramName)
        inc argIdx

  var callExpr = newCall(procName)
  for arg in callArgs:
    callExpr.add(arg)

  result = quote do:
    `prc`

    proc `wrapperName`(`ctxIdent`: Context) {.async, gcsafe.} =
      try:
        let body = parseJson(`ctxIdent`.request.body)
        let `argsIdent` = body["args"]
        `extractStmts`
        let res = `callExpr`
        `ctxIdent`.json(%*{"result": res})
      except KeyError as e:
        `ctxIdent`.status(400).json(%*{"error": "Missing argument: " & e.msg})
      except JsonParsingError:
        `ctxIdent`.status(400).json(%*{"error": "Invalid JSON body"})
      except Exception as e:
        `ctxIdent`.status(500).json(%*{"error": e.msg})

    Route.post("/rpc/" & `procNameStr`, `wrapperName`)

# ─── SERVER THREAD ───────────────────────────────────────────────────────────────
# Jazzy HTTP server runs on a background thread so it doesn't block the Webview UI.

type ServerConfig = object
  port: int
  address: string
  prodDir: string

var serverThread: Thread[ServerConfig]

proc runJazzyServer(cfg: ServerConfig) {.thread.} =
  {.cast(gcsafe).}:
    if cfg.prodDir.len > 0 and dirExists(cfg.prodDir):
      Jazzy.static(cfg.prodDir, "/")

    Jazzy.use(jmw.cors(allowedOrigin = "*"))

    Jazzy.serve(cfg.port, cfg.address)

# ─── VFS MACRO ───────────────────────────────────────────────────────────────
macro embedDir*(dir: static[system.string]): untyped =
  var tblAssigns = newStmtList()
  let vfsIdent = ident("vfs")
  
  let targetDir = getProjectPath() / dir
  
  for path in walkDirRec(targetDir):
    let relPath = "/" & path.relativePath(targetDir).replace('\\', '/')
    let content = slurp(path)
    let pathLit = newLit(relPath)
    let contentLit = newLit(content)
    tblAssigns.add quote do:
      `vfsIdent`[`pathLit`] = `contentLit`

  result = quote do:
    block:
      var `vfsIdent` = newTable[system.string, system.string]()
      `tblAssigns`
      `vfsIdent`

# ─── ENTRY POINT ───────────────────────────────────────────────────────────────

proc runDesktopAppInternal*(
  title: system.string,
  width: int,
  height: int,
  targetUrl: system.string,
  port: int,
  address: system.string
) =
  let cfg = ServerConfig(port: port, address: address, prodDir: "")
  createThread(serverThread, runJazzyServer, cfg)

  # Allow Jazzy to bind before the webview tries to connect
  sleep(500)

  let w = webview_ffi.create(0, nil)
  if w == nil:
    quit("Failed to create webview instance")

  w.setTitle(cstring(title))
  w.setSize(cint(width), cint(height), WebviewHint.None)
  w.navigate(cstring(targetUrl))
  discard w.run()
  discard w.destroy()

  joinThread(serverThread)

template startDesktopApp*(
  title: system.string,
  width: int = 1024,
  height: int = 768,
  devUrl: system.string = "",
  prodDir: static[system.string] = ""
) =
  let rpcPort = 8080
  let rpcAddress = "127.0.0.1"

  when prodDir.len > 0:
    import std/mimetypes
    let embeddedVfs = embedDir(prodDir)
    let m = newMimetypes()
    
    proc handleVfs(ctx: Context) {.async, gcsafe.} =
      {.cast(gcsafe).}:
        var path = ctx.request.path
        if path == "/": path = "/index.html"
        if embeddedVfs.hasKey(path):
          let ext = path.splitFile().ext
          let mime = m.getMimetype(ext, default="application/octet-stream")
          ctx.header("Content-Type", mime)
          ctx.response.body = embeddedVfs[path]
        else:
          ctx.status(404).text("Not Found in VFS")
        
    Route.get("/{path...}", handleVfs)
    Route.get("/", handleVfs)

  let targetUrl =
    if devUrl.len > 0: devUrl
    elif prodDir.len > 0: "http://" & rpcAddress & ":" & $rpcPort
    else: "data:text/html,<h1>No frontend configured</h1>"

  runDesktopAppInternal(title, width, height, targetUrl, rpcPort, rpcAddress)
