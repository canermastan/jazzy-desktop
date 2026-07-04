import std/[json, macros, os, asyncdispatch, tables, strutils]
import jazzy
import webview_ffi

import ./macros
import ./server
import ./window
import ./events
import ./dialogs
import ./clipboard
import ./lifecycle
import ./tray
import ./browser
import ./logger
import ./store
export jazzy
export webview_ffi
export tables, strutils
export macros, server, window, events, dialogs, clipboard, lifecycle, tray, browser, logger, store

var gAppWebview*: Webview

proc runDesktopAppInternal*(
  title: system.string,
  width: int,
  height: int,
  targetUrl: system.string,
  port: int,
  address: system.string,
  frameless: bool,
  resizable: bool
) =
  let cfg = ServerConfig(port: port, address: address, prodDir: "")
  createThread(serverThread, runJazzyServer, cfg)

  # Allow Jazzy to bind before the webview tries to connect
  sleep(500)

  let w = webview_ffi.create(0, nil)
  if w == nil:
    quit("Failed to create webview instance")

  gAppWebview = w
  bindNativeWindowControls(w)
  if frameless:
    applyFramelessAndMica(w)

  w.setTitle(cstring(title))
  let hint = if resizable: WebviewHint.None else: WebviewHint.Fixed
  w.setSize(cint(width), cint(height), hint)
  w.navigate(cstring(targetUrl))
  discard w.run()      # blocks until the window is closed
  discard w.destroy()
  quit(0)              # kills the HTTP server thread too

template startDesktopApp*(
  title: system.string,
  width: int = 1024,
  height: int = 768,
  devUrl: system.string = "",
  prodDir: static[system.string] = "",
  frameless: bool = false,
  resizable: bool = true
) =
  let rpcPort = 8080
  let rpcAddress = "127.0.0.1"

  when prodDir.len > 0:
    import std/mimetypes
    let embeddedVfs = embedDir(prodDir)
    let m = newMimetypes()
    
    let vfsMw = Middleware(
      name: "vfsMw",
      handler: proc(ctx: Context, next: HandlerProc): Future[void] {.async, gcsafe.} =
        {.cast(gcsafe).}:
          var path = ctx.request.path
          if path == "/": path = "/index.html"
          
          if embeddedVfs.hasKey(path):
            let ext = path.splitFile().ext
            let mime = m.getMimetype(ext, default="application/octet-stream")
            ctx.status(200)
            ctx.header("Content-Type", mime)
            ctx.response.body = embeddedVfs[path]
          else:
            await next(ctx)
    )
    Jazzy.use(vfsMw)

  let targetUrl =
    when defined(release):
      if prodDir.len > 0: "http://" & rpcAddress & ":" & $rpcPort
      else: "data:text/html,<h1>No frontend configured</h1>"
    else:
      if devUrl.len > 0: devUrl
      elif prodDir.len > 0: "http://" & rpcAddress & ":" & $rpcPort
      else: "data:text/html,<h1>No frontend configured</h1>"

  runDesktopAppInternal(title, width, height, targetUrl, rpcPort, rpcAddress, frameless, resizable)
