# src/app.nim
import jazzy_desktop

# Expose a Nim proc as an HTTP RPC endpoint at POST /rpc/sayHello
proc sayHello(name: string, age: int): string {.expose.} =
  "Hello " & name & ", you are " & $age & " years old!"

# Test Context injection
proc saveUserSettings(ctx: Context, theme: string): bool {.expose.} =
  echo "Saving theme: ", theme, " on path: ", ctx.request.path
  return true

# Test Advanced Type Marshalling
type User = object
  id: int
  name: string
  roles: seq[string]

proc saveUser(user: User): User {.expose.} =
  echo "Saving user: ", user.name, " with roles: ", user.roles
  return user

# ─── DATABASE TEST ─────────────────────────────────────────────────────────────
import jazzy/db/[database, builder, schema]
import std/json

connectDB("app.db")
let sb = createTable("test_logs")
discard sb.increments("id")
discard sb.string("message")
discard sb.timestamp("created_at", default="CURRENT_TIMESTAMP")
sb.execute()

proc saveLog(ctx: Context, msg: string): bool {.expose.} =
  {.cast(gcsafe).}:
    discard DB.table("test_logs").insert(%*{"message": msg})
  return true

proc getLogs(ctx: Context): JsonNode {.expose.} =
  {.cast(gcsafe).}:
    return DB.table("test_logs").get()

import std/os

proc runProgressTask(): bool {.expose.} =
  # Simulate a progress-heavy background task
  for i in 1..20:
    sleep(50)
    emit("progress", %*{"percent": i * 5})
  return true

proc pickFile(): string {.expose.} =
  return selectFileDialog("Select a file to process", @[
    DialogFilter(name: "Image Files", extensions: "*.png;*.jpg;*.jpeg"),
    DialogFilter(name: "All Files", extensions: "*.*")
  ], forSave = false)

proc showAlert(msg: string): bool {.expose.} =
  showMessageBox("System Alert", msg, mbWarning)
  return true

proc readCb(): string {.expose.} =
  return readClipboard()

proc writeCb(text: string): bool {.expose.} =
  return writeClipboard(text)

proc handleMyItem() =
  showMessageBox("Jazzy Desktop", "Custom Tray Menu Item Clicked!", mbInfo)

proc showTray(tooltip: string): bool {.expose.} =
  {.cast(gcsafe).}:
    initTray(gAppWebview, tooltip, @[
      TrayMenuItem(id: 1, label: "Jazzy Settings", callback: handleMyItem)
    ])
  return true

# Initialize Logger
initLogger("app_debug.log")
logInfo("Jazzy Desktop App Started!")

proc openExternalLink(url: string): bool {.expose.} =
  return openBrowser(url)

proc writeLog(msg: string): bool {.expose.} =
  {.cast(gcsafe).}:
    logInfo("Frontend Log: " & msg)
  return true

# Prevent multiple instances from running
enforceSingleInstance("JazzyDesktopApp_123")

startDesktopApp(
  title = "Jazzy Desktop App",
  width = 1024,
  height = 768,
  devUrl = "http://localhost:5173",
  prodDir = "../frontend/dist",
  #frameless = false
)
