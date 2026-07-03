import std/[os, strutils, osproc, terminal]

const CSS_TEMPLATE = """
body {
  margin: 0;
  padding: 0;
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
  background: linear-gradient(135deg, #0f172a, #1e293b);
  color: #f8fafc;
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  user-select: none;
}

.jazzy-container {
  text-align: center;
  padding: 40px;
  background: rgba(255, 255, 255, 0.05);
  backdrop-filter: blur(10px);
  border-radius: 20px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5);
  animation: fadeIn 1s ease-out;
}

h1 {
  font-size: 2.5rem;
  margin-bottom: 10px;
  background: -webkit-linear-gradient(45deg, #38bdf8, #818cf8);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}

p {
  color: #94a3b8;
  margin-bottom: 30px;
}

button {
  background: #3b82f6;
  color: white;
  border: none;
  padding: 12px 24px;
  font-size: 1rem;
  font-weight: 600;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s ease;
}

button:hover {
  background: #2563eb;
  transform: translateY(-2px);
  box-shadow: 0 10px 15px -3px rgba(59, 130, 246, 0.4);
}

button:active {
  transform: translateY(0);
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(20px); }
  to { opacity: 1; transform: translateY(0); }
}
"""

const APP_NIM_TEMPLATE = """
import jazzy_desktop

proc sayHello(name: string, age: int): string {.expose.} =
  "Hello " & name & ", you are " & $age & " years old!"

initLogger("app_debug.log")
logInfo("Jazzy Desktop App Started!")

startDesktopApp(
  title = "Jazzy Desktop App",
  width = 1024,
  height = 768,
  devUrl = "http://localhost:5173",
  prodDir = "../frontend/dist"
)
"""

const JAZZY_JS_TEMPLATE = """
const RPC_BASE = "http://127.0.0.1:8080/rpc";
const WS_URL = "ws://127.0.0.1:8080/_jazzy/events";

const listeners = {};
let ws = null;

function connectWs() {
  ws = new WebSocket(WS_URL);
  ws.onmessage = (event) => {
    try {
      const data = JSON.parse(event.data);
      if (listeners[data.event]) {
        listeners[data.event].forEach((cb) => {
          try { cb(data.payload); } catch (e) { console.error(e); }
        });
      }
    } catch (err) {}
  };
  ws.onclose = () => setTimeout(connectWs, 1000);
  ws.onerror = (err) => { if(ws) ws.close(); };
}

if (typeof window !== "undefined") connectWs();

const client = {
  on(event, callback) {
    if (!listeners[event]) listeners[event] = [];
    listeners[event].push(callback);
  },
  off(event, callback) {
    if (!listeners[event]) return;
    listeners[event] = listeners[event].filter((cb) => cb !== callback);
  }
};

export const jazzy = new Proxy(client, {
  get(target, prop) {
    if (prop in target) return target[prop];
    if (typeof prop === "symbol" || prop.startsWith("_")) return undefined;

    return async (...args) => {
      const response = await fetch(`${RPC_BASE}/${String(prop)}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ args }),
      });

      if (!response.ok) {
        const err = await response.json().catch(() => ({ error: response.statusText }));
        throw new Error(err.error ?? `RPC error: ${response.status}`);
      }

      const data = await response.json();
      return data.result;
    };
  },
});
"""

const JAZZY_TS_TEMPLATE = """
const RPC_BASE = "http://127.0.0.1:8080/rpc";
const WS_URL = "ws://127.0.0.1:8080/_jazzy/events";

const listeners: Record<string, Function[]> = {};
let ws: WebSocket | null = null;

function connectWs() {
  ws = new WebSocket(WS_URL);
  ws.onmessage = (event) => {
    try {
      const data = JSON.parse(event.data);
      if (listeners[data.event]) {
        listeners[data.event].forEach((cb) => {
          try { cb(data.payload); } catch (e) { console.error(e); }
        });
      }
    } catch (err) {}
  };
  ws.onclose = () => setTimeout(connectWs, 1000);
  ws.onerror = (err) => { if(ws) ws.close(); };
}

if (typeof window !== "undefined") connectWs();

const client = {
  on(event: string, callback: Function) {
    if (!listeners[event]) listeners[event] = [];
    listeners[event].push(callback);
  },
  off(event: string, callback: Function) {
    if (!listeners[event]) return;
    listeners[event] = listeners[event].filter((cb) => cb !== callback);
  }
};

export const jazzy: any = new Proxy(client, {
  get(target: any, prop: string | symbol) {
    if (prop in target) return target[prop];
    if (typeof prop === "symbol" || prop.startsWith("_")) return undefined;

    return async (...args: any[]) => {
      const response = await fetch(`${RPC_BASE}/${String(prop)}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ args }),
      });

      if (!response.ok) {
        const err = await response.json().catch(() => ({ error: response.statusText }));
        throw new Error(err.error ?? `RPC error: ${response.status}`);
      }

      const data = await response.json();
      return data.result;
    };
  },
});
"""

const REACT_TEMPLATE = """
import { useState } from 'react'
import { jazzy } from './jazzy'
import './index.css'

function App() {
  const [msg, setMsg] = useState("Click the button to test RPC")

  const handleClick = async () => {
    try {
      const response = await jazzy.sayHello("Developer", 99)
      setMsg("It's Working!! " + response)
    } catch (err) {
      setMsg("Error: " + err.message)
    }
  }

  return (
    <div className="jazzy-container">
      <h1>Welcome to Jazzy Desktop</h1>
      <p>{msg}</p>
      <button onClick={handleClick}>Test Connection</button>
    </div>
  )
}

export default App
"""

const VUE_TEMPLATE = """
<script setup>
import { ref } from 'vue'
import { jazzy } from './jazzy'

const msg = ref("Click the button to test RPC")

const handleClick = async () => {
  try {
    const response = await jazzy.sayHello("Developer", 99)
    msg.value = "It's Working!! " + response
  } catch (err) {
    msg.value = "Error: " + err.message
  }
}
</script>

<template>
  <div class="jazzy-container">
    <h1>Welcome to Jazzy Desktop</h1>
    <p>{{ msg }}</p>
    <button @click="handleClick">Test Connection</button>
  </div>
</template>

<style>
@import './style.css';
</style>
"""

const SVELTE_TEMPLATE = """
<script>
  import { jazzy } from './jazzy'
  import './app.css'

  let msg = "Click the button to test RPC"

  const handleClick = async () => {
    try {
      const response = await jazzy.sayHello("Developer", 99)
      msg = "It's Working!! " + response
    } catch (err) {
      msg = "Error: " + err.message
    }
  }
</script>

<main class="jazzy-container">
  <h1>Welcome to Jazzy Desktop</h1>
  <p>{msg}</p>
  <button on:click={handleClick}>Test Connection</button>
</main>
"""

const SOLID_TEMPLATE = """
import { createSignal } from 'solid-js'
import { jazzy } from './jazzy'
import './index.css'

function App() {
  const [msg, setMsg] = createSignal("Click the button to test RPC")

  const handleClick = async () => {
    try {
      const response = await jazzy.sayHello("Developer", 99)
      setMsg("It's Working!! " + response)
    } catch (err) {
      setMsg("Error: " + err.message)
    }
  }

  return (
    <div class="jazzy-container">
      <h1>Welcome to Jazzy Desktop</h1>
      <p>{msg()}</p>
      <button onClick={handleClick}>Test Connection</button>
    </div>
  )
}

export default App
"""

const VANILLA_TEMPLATE = """
import './style.css'
import { jazzy } from './jazzy'

document.querySelector('#app').innerHTML = `
  <div class="jazzy-container">
    <h1>Welcome to Jazzy Desktop</h1>
    <p id="msg">Click the button to test RPC</p>
    <button id="btn">Test Connection</button>
  </div>
`

document.querySelector('#btn').addEventListener('click', async () => {
  const msgEl = document.querySelector('#msg')
  try {
    const response = await jazzy.sayHello("Developer", 99)
    msgEl.textContent = "It's Working!! " + response
  } catch (err) {
    msgEl.textContent = "Error: " + err.message
  }
})
"""

proc promptInt(msg: string, min, max: int): int =
  while true:
    stdout.write(msg)
    stdout.flushFile()
    let input = stdin.readLine().strip()
    try:
      let val = input.parseInt()
      if val >= min and val <= max:
        return val
    except:
      discard
    echo "Please enter a number between ", min, " and ", max, "."

proc runNew*(projectName: string) =
  if dirExists(projectName):
    styledEcho fgRed, "❌ Error: Directory '", projectName, "' already exists!"
    quit(1)

  styledEcho styleBright, fgCyan, "🛠️  Creating Jazzy Desktop Project: ", projectName
  echo ""
  styledEcho fgYellow, "Which UI library would you like to use?"


  echo "1. Svelte (Recommended for simplicity)"
  echo "2. React"
  echo "3. SolidJS"
  echo "4. Vue"
  echo "5. Vanilla JS"
  let uiChoice = promptInt("Your choice (1-5): ", 1, 5)

  echo ""
  styledEcho fgYellow, "Would you like to use TypeScript?"
  echo "1. Yes"

  echo "2. No"
  let tsChoice = promptInt("Your choice (1-2): ", 1, 2)
  let isTs = tsChoice == 1

  var viteTemplate = ""
  var ext = if isTs: "ts" else: "js"
  var jsxExt = if isTs: "tsx" else: "jsx"
  
  case uiChoice:
  of 1: viteTemplate = if isTs: "svelte-ts" else: "svelte"
  of 2: viteTemplate = if isTs: "react-ts" else: "react"
  of 3: viteTemplate = if isTs: "solid-ts" else: "solid"
  of 4: viteTemplate = if isTs: "vue-ts" else: "vue"
  of 5: viteTemplate = if isTs: "vanilla-ts" else: "vanilla"
  else: discard

  createDir(projectName)
  setCurrentDir(projectName)

  # Create Vite project
  styledEcho fgMagenta, "\n⏳ Scaffolding Vite project..."
  let createCmd = "npx --yes create-vite@latest frontend --template " & viteTemplate

  let shellCmd = if defined(windows): "cmd.exe /c " & createCmd else: createCmd
  discard execCmd(shellCmd)

  if not dirExists("frontend"):
    styledEcho fgRed, "❌ Error: Failed to scaffold Vite project."
    quit(1)

  # Create Nim backend
  styledEcho fgMagenta, "⏳ Preparing backend skeleton..."
  createDir("src")

  writeFile("src" / "app.nim", APP_NIM_TEMPLATE)
  
  # Inject jazzy.js into frontend
  styledEcho fgMagenta, "⏳ Injecting Jazzy Desktop connections..."
  let jazzyFile = "frontend" / "src" / "jazzy." & ext

  if isTs:
    writeFile(jazzyFile, JAZZY_TS_TEMPLATE)
  else:
    writeFile(jazzyFile, JAZZY_JS_TEMPLATE)

  # Inject specific templates
  case uiChoice:
  of 1: # Svelte
    writeFile("frontend" / "src" / "app.css", CSS_TEMPLATE)
    writeFile("frontend" / "src" / "App.svelte", SVELTE_TEMPLATE)
  of 2: # React
    writeFile("frontend" / "src" / "index.css", CSS_TEMPLATE)
    writeFile("frontend" / "src" / ("App." & jsxExt), REACT_TEMPLATE)
  of 3: # SolidJS
    writeFile("frontend" / "src" / "index.css", CSS_TEMPLATE)
    writeFile("frontend" / "src" / ("App." & jsxExt), SOLID_TEMPLATE)
  of 4: # Vue
    writeFile("frontend" / "src" / "style.css", CSS_TEMPLATE)
    writeFile("frontend" / "src" / "App.vue", VUE_TEMPLATE)
  of 5: # Vanilla
    writeFile("frontend" / "src" / "style.css", CSS_TEMPLATE)
    writeFile("frontend" / "src" / ("main." & ext), VANILLA_TEMPLATE)
  else: discard

  # Run npm install quietly
  styledEcho fgMagenta, "⏳ Installing NPM packages (Please wait)..."
  setCurrentDir("frontend")

  let npmCmd = "npm install"
  let npmShellCmd = if defined(windows): "cmd.exe /c " & npmCmd else: npmCmd
  let (npmOut, npmCode) = execCmdEx(npmShellCmd)
  if npmCode != 0:
    styledEcho fgRed, "⚠️ Error installing NPM packages. Please try running 'npm install' manually."
  setCurrentDir("..") # back to project root
  
  # Success Message
  styledEcho styleBright, fgGreen, "\n✅ Project successfully created!"
  styledEcho fgWhite, "\nTo get started:"
  styledEcho styleBright, fgCyan, "  cd ", projectName
  styledEcho styleBright, fgCyan, "  jazzyd dev"
  styledEcho styleBright, fgGreen, "\nHappy coding! 🎷"

