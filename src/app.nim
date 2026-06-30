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

startDesktopApp(
  title = "Jazzy Desktop App",
  width = 1024,
  height = 768,
  devUrl = "http://localhost:5173",
  prodDir = "../frontend/dist"
)
