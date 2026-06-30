# src/app.nim
import jazzy_desktop

# 1. Simple RPC: Types are strictly validated and handled by the macro
proc sayHello(name: string, age: int): string {.expose.} =
  return "Hello " & name & ", you are " & $age & " years old!"

# 2. Start the application
# Use the Vite dev server URL
startDesktopApp(
  title = "Jazzy Desktop App",
  width = 1024,
  height = 768,
  devUrl = "http://localhost:5173"
)
