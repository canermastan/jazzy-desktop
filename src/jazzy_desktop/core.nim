import webview_ffi
import std/[json, macros]

export webview_ffi

# Global list of procs that will bind the exposed functions to the webview instance
type BinderProc = proc(w: Webview)
var exposedBinders*: seq[BinderProc] = @[]

macro expose*(prc: untyped): untyped =
  prc.expectKind(nnkProcDef)
  let procName = prc[0]
  let procNameStr = $procName
  let params = prc[3]
  
  let wrapperName = genSym(nskProc, "wrapper_" & procNameStr)
  
  var extractStmts = newStmtList()
  var callArgs = newSeq[NimNode]()
  var argIdx = 0
  let argsIdent = ident("args")
  
  # Iterate over parameters (skipping the return type at index 0)
  for i in 1 ..< params.len:
    let paramDefs = params[i]
    let paramType = paramDefs[^2]
    
    # Handle multiple parameters of the same type (e.g. `a, b: int`)
    for j in 0 ..< paramDefs.len - 2:
      let paramName = paramDefs[j]
      let typeStr = $paramType
      
      # Generate extraction logic based on type
      let extractStmt = if typeStr == "string":
        quote do:
          let `paramName` = `argsIdent`[`argIdx`].getStr()
      elif typeStr == "int":
        quote do:
          let `paramName` = `argsIdent`[`argIdx`].getInt()
      else:
        # Fallback for complex types using std/json `to()`
        quote do:
          let `paramName` = to(`argsIdent`[`argIdx`], `paramType`)
      
      extractStmts.add(extractStmt)
      callArgs.add(paramName)
      inc argIdx
      
  var callExpr = newCall(procName)
  for arg in callArgs:
    callExpr.add(arg)
  
  # Build the final AST: the original proc + the wrapper + registration
  result = quote do:
    `prc`
    
    proc `wrapperName`(seqId: cstring, req: cstring, arg: pointer) {.cdecl.} =
      let w = cast[Webview](arg)
      let `argsIdent` = parseJson($req)
      `extractStmts`
      let res = `callExpr`
      
      # Prepare the response (wrapped in a message object for now as per spec)
      let responseObj = %*{"message": res}
      w.returnResult(seqId, 0, cstring($responseObj))
      
    exposedBinders.add(proc(w: Webview) =
      discard w.bindFn(`procNameStr`, `wrapperName`, w)
    )

proc startDesktopApp*(title: string, width: int = 1024, height: int = 768, devUrl: string = "", htmlContent: string = "") =
  let w = webview_ffi.create(1, nil)
  if w == nil:
    quit("Failed to create webview instance")

  w.setTitle(cstring(title))
  w.setSize(cint(width), cint(height), WebviewHint.None)
  
  # Register all exposed macros
  for binder in exposedBinders:
    binder(w)

  if htmlContent.len > 0:
    w.setHtml(cstring(htmlContent))
  elif devUrl.len > 0:
    w.navigate(cstring(devUrl))
  else:
    w.setHtml("<h1>No content provided</h1>")

  discard w.run()
  discard w.destroy()
