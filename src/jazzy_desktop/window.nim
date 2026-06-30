import std/json
import webview_ffi

proc windowCloseCb*(seqId, req: cstring, arg: pointer) {.cdecl.} =
  let w = cast[Webview](arg)
  w.terminate()

proc windowSetTitleCb*(seqId, req: cstring, arg: pointer) {.cdecl.} =
  let w = cast[Webview](arg)
  try:
    let args = parseJson($req)
    if args.len > 0 and args[0].kind == JString:
      w.setTitle(cstring(args[0].getStr()))
  except:
    discard

proc windowSetSizeCb*(seqId, req: cstring, arg: pointer) {.cdecl.} =
  let w = cast[Webview](arg)
  try:
    let args = parseJson($req)
    if args.len >= 2 and args[0].kind == JInt and args[1].kind == JInt:
      w.setSize(cint(args[0].getInt()), cint(args[1].getInt()), WebviewHint.None)
  except:
    discard

proc bindNativeWindowControls*(w: Webview) =
  discard w.bindFn("close", windowCloseCb, w)
  discard w.bindFn("setTitle", windowSetTitleCb, w)
  discard w.bindFn("setSize", windowSetSizeCb, w)
