import std/[json, macros, os, asyncdispatch]
import jazzy
import jazzy/core/middlewares as jmw
import webview_ffi

export jazzy
export webview_ffi

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

  for i in 1 ..< params.len:
    let paramDefs = params[i]
    let paramType = paramDefs[^2]

    for j in 0 ..< paramDefs.len - 2:
      let paramName = paramDefs[j]
      let typeStr = $paramType

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

    proc `wrapperName`(ctx: Context) {.async, gcsafe.} =
      try:
        let body = parseJson(ctx.request.body)
        let `argsIdent` = body["args"]
        `extractStmts`
        let res = `callExpr`
        ctx.json(%*{"result": res})
      except KeyError as e:
        ctx.status(400).json(%*{"error": "Missing argument: " & e.msg})
      except JsonParsingError:
        ctx.status(400).json(%*{"error": "Invalid JSON body"})
      except Exception as e:
        ctx.status(500).json(%*{"error": e.msg})

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

# ─── ENTRY POINT ───────────────────────────────────────────────────────────────
# startDesktopApp starts the Jazzy HTTP server on a background thread,
# then opens the Webview window on the main thread (blocking).

proc startDesktopApp*(
  title: string,
  width: int = 1024,
  height: int = 768,
  devUrl: string = "",
  prodDir: string = ""
) =
  let rpcPort = 8080
  let rpcAddress = "127.0.0.1"

  let cfg = ServerConfig(port: rpcPort, address: rpcAddress, prodDir: prodDir)
  createThread(serverThread, runJazzyServer, cfg)

  # Allow Jazzy to bind before the webview tries to connect
  sleep(500)

  let targetUrl =
    if devUrl.len > 0:
      devUrl
    elif prodDir.len > 0:
      "http://" & rpcAddress & ":" & $rpcPort
    else:
      "data:text/html,<h1>No frontend configured</h1>"

  let w = webview_ffi.create(0, nil)
  if w == nil:
    quit("Failed to create webview instance")

  w.setTitle(cstring(title))
  w.setSize(cint(width), cint(height), WebviewHint.None)
  w.navigate(cstring(targetUrl))
  discard w.run()
  discard w.destroy()

  joinThread(serverThread)
