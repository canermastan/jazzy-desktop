## Jazzy Desktop CLI Tool (jazzyd)
## Usage:
##   jazzyd dev     - Start Vite frontend and Nim backend with Hot-Reload
##   jazzyd build   - Build Vite frontend and compile Nim backend for production

import std/[os, osproc, strutils, times, tables, strformat, streams]

const BANNER = """
    __  ___  _____ _____ __  ______ 
 __/ / / _ |/_  //_  // / / / __  / 
/ __/ / __ | / /_ / /_ / /_/ / / /_ 
\__/ /_/ |_|/___//___/ \__, /  \__/ 
                      /____/        
  Jazzy Desktop CLI - v0.1.0
"""

proc showHelp() =
  echo BANNER
  echo "Usage:"
  echo "  jazzyd dev     Start dev server with hot-reload"
  echo "  jazzyd build   Build production EXE"
  echo "  jazzyd help    Show this help"
  echo ""

# ─── FRONTEND COMMANDS ────────────────────────────────────────────────────────
var frontendProc: Process = nil

proc runNpmDev(workingDir: string): Process =
  when defined(windows):
    result = startProcess("cmd.exe", args=["/c", "npm", "run", "dev"], workingDir=workingDir, options={poUsePath})
  else:
    result = startProcess("npm", args=["run", "dev"], workingDir=workingDir, options={poUsePath})

proc runNpmBuild(workingDir: string): Process =
  when defined(windows):
    let cmdArgs = @["/c", "npm", "run", "build"]
    result = startProcess("cmd.exe", args=cmdArgs, workingDir=workingDir, options={poUsePath, poStdErrToStdOut})
  else:
    result = startProcess("npm", args=["run", "build"], workingDir=workingDir, options={poUsePath, poStdErrToStdOut})

# ─── BACKEND COMMANDS ─────────────────────────────────────────────────────────
var backendProc: Process = nil

proc buildBackend(isDev: bool, iconRes: string = ""): bool =
  echo "🎷 [jazzyd] Compiling Nim backend..."
  var args = @["cpp", "--threads:on"]
  if not isDev:
    args.add("-d:release")
    args.add("--app:gui")
  if iconRes.len > 0:
    args.add("--passL:" & iconRes)
  args.add("src" / "app.nim")
  
  let p = startProcess("nim", args=args, options={poUsePath, poStdErrToStdOut})
  var output = ""
  for line in p.lines:
    output.add(line & "\n")
    if line.len > 0:
      let displayLine = if line.len > 65: line[0..62] & "..." else: line
      let padding = if displayLine.len < 65: repeat(' ', 65 - displayLine.len) else: ""
      stdout.write("\r  ⏳ " & displayLine & padding)
      stdout.flushFile()
      
  echo "" # Move to next line after compilation finishes
  let code = p.waitForExit()
  p.close()
  if code != 0:
    echo "❌ [jazzyd] Backend Compile Error:\n", output
  return code == 0

proc startBackend() =
  if buildBackend(true):
    echo "🎷 [jazzyd] Starting app..."
    when defined(windows):
      let exePath = "src" / "app.exe"
    else:
      let exePath = "src" / "app"
    # poDefaultFlags olmadan baslat: app ayri bir process olarak calismali,
    # terminal sinyallerini (Ctrl-C gibi) devralmamali.
    backendProc = startProcess(exePath, options={poUsePath})
  else:
    echo "❌ [jazzyd] Build failed. Waiting for file changes..."

proc stopBackend() =
  if backendProc != nil and backendProc.running():
    echo "🎷 [jazzyd] Stopping current app instance..."
    backendProc.terminate()
    discard backendProc.waitForExit()
    backendProc.close()
    backendProc = nil

proc stopFrontend() =
  if frontendProc != nil and frontendProc.running():
    when defined(windows):
      discard execShellCmd("taskkill /F /T /PID " & $frontendProc.processID() & " > NUL 2>&1")
    else:
      frontendProc.terminate()
    frontendProc.close()
    frontendProc = nil

proc cleanExit() {.noconv.} =
  echo "\n👋 [jazzyd] Caught Ctrl+C. Cleaning up..."
  stopBackend()
  stopFrontend()
  quit(0)

setControlCHook(cleanExit)

# ─── FILE WATCHER (HOT RELOAD) ────────────────────────────────────────────────
proc getSourceFiles(dir: string): seq[string] =
  result = @[]
  if not dirExists(dir): return
  for file in walkDirRec(dir):
    if file.endsWith(".nim"):
      result.add(file)

proc runDev() =
  echo BANNER
  echo "Starting Jazzy Desktop in DEV mode..."
  
  # Start Frontend
  frontendProc = runNpmDev("frontend")
  
  # Initialize File Watcher
  var fileTimes = initTable[string, Time]()
  for f in getSourceFiles("src"):
    fileTimes[f] = getLastModificationTime(f)
    
  startBackend()
  
  try:
    while true:
      sleep(500)
      
      # App kapatıldıysa CLI'ı da sonlandır
      if backendProc != nil and not backendProc.running():
        echo "\n👋 [jazzyd] App closed by user. Exiting dev mode..."
        break

      var changed = false
      for f in getSourceFiles("src"):
        let mt = try: getLastModificationTime(f) except: Time()
        if not fileTimes.hasKey(f) or fileTimes[f] != mt:
          fileTimes[f] = mt
          changed = true
          
      if changed:
        echo "\n🔄 [jazzyd] File change detected! Reloading..."
        stopBackend()
        startBackend()
  finally:
    stopBackend()
    stopFrontend()

# ─── BUILD PIPELINE ───────────────────────────────────────────────────────────
proc runBuild() =
  echo BANNER
  echo "📦 Starting Jazzy Desktop PRODUCTION build..."
  
  echo "\n[1/3] Building Vite Frontend..."
  let fProc = runNpmBuild("frontend")
  let output = fProc.outputStream.readAll()
  let code = fProc.waitForExit()
  fProc.close()
  if code != 0:
    echo "❌ Frontend build failed!\n", output
    quit(1)
  
  var iconRes = ""
  when defined(windows):
    if fileExists("app_icon.ico"):
      echo "\n[2/3] Embedding application icon..."
      writeFile("jazzy_icon.rc", "101 ICON \"app_icon.ico\"")
      let wcode = execShellCmd("windres jazzy_icon.rc -O coff -o jazzy_icon.res")
      if wcode == 0 and fileExists("jazzy_icon.res"):
        iconRes = "jazzy_icon.res"
        echo "✅ Icon compiled successfully."
      else:
        echo "⚠️ Failed to compile icon using windres. Proceeding without icon."
    else:
      echo "\n[2/3] No app_icon.ico found in project root. Skipping icon embedding."
  else:
    echo "\n[2/3] Icon embedding is currently only supported on Windows."
  
  echo "\n[3/3] Compiling Nim Backend (Release + GUI)..."
  if buildBackend(false, iconRes):
    echo "\n✅ Build completed successfully! Check the src/ directory for your executable."
  else:
    echo "❌ Backend build failed!"
    quit(1)
    
  when defined(windows):
    if fileExists("jazzy_icon.rc"): removeFile("jazzy_icon.rc")
    if fileExists("jazzy_icon.res"): removeFile("jazzy_icon.res")

# ─── MAIN ─────────────────────────────────────────────────────────────────────
when isMainModule:
  let args = commandLineParams()
  if args.len == 0:
    showHelp()
    quit(0)
    
  case args[0].toLowerAscii()
  of "dev":
    runDev()
  of "build":
    runBuild()
  of "help", "--help", "-h":
    showHelp()
  else:
    echo "❌ Unknown command: ", args[0]
    showHelp()
    quit(1)
