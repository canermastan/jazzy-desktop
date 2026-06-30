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

startDesktopApp(
  title = "Jazzy Desktop App",
  width = 1024,
  height = 768,
  devUrl = "http://localhost:5173",
  prodDir = "../frontend/dist"
)
