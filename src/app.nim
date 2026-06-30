# src/app.nim
import jazzy_desktop

# Expose a Nim proc as an HTTP RPC endpoint at POST /rpc/sayHello
proc sayHello(name: string, age: int): string {.expose.} =
  "Hello " & name & ", you are " & $age & " years old!"

startDesktopApp(
  title = "Jazzy Desktop App",
  width = 1024,
  height = 768,
  devUrl = "http://localhost:5173",
  prodDir = "../frontend/dist"
)
