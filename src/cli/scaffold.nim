import std/[os, strutils, osproc, terminal]

const nimblePath = static:
  var path = ""
  let baseDir = currentSourcePath().parentDir()
  let attempts = [
    baseDir / ".." / ".." / "jazzy_desktop.nimble"
  ]
  for a in attempts:
    if fileExists(a):
      path = a
      break
  path

proc getVersion(): string =
  when nimblePath == "":
    return "0.1.0"
  else:
    let content = staticRead(nimblePath)
    for line in content.splitLines():
      if line.startsWith("version"):
        let parts = line.split("=")
        if parts.len > 1:
          return parts[1].strip().strip(chars = {'"'})
    return "0.1.0"

const JAZZY_DESKTOP_VERSION* = getVersion()
const CSS_TEMPLATE = """
*, *::before, *::after { margin: 0; padding: 0; box-sizing: border-box; }
 
  body {
    min-height: 100vh;
    background: linear-gradient(135deg, #0f172a, #1e293b);
    color: #f8fafc;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
    gap: 3rem;
    overflow: hidden;
  }
 
  /* Grain */
  body::before {
    content: '';
    position: fixed;
    inset: -50%; width: 200%; height: 200%;
    background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 200 200' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.75' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E");
    background-size: 180px 180px;
    opacity: 0.035;
    pointer-events: none;
    animation: grain .1s steps(1) infinite;
  }
  @keyframes grain {
    0%  { transform:translate(0,0); }   25% { transform:translate(-3%,2%); }
    50% { transform:translate(2%,-3%); } 75% { transform:translate(-2%,3%); }
  }
 
  .jazzy-container {
    text-align: center;
  }
 
  h1 {
    font-size: clamp(1.8rem,4vw,2.8rem);
    font-weight: 600;
    color: rgba(255,255,255,.9);
    letter-spacing: -.02em;
    background: -webkit-linear-gradient(45deg, #38bdf8, #818cf8);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
  }
 
  /* ── Buttons grid ── */
  .grid {
    display: flex;
    flex-wrap: wrap;
    gap: 1rem;
    justify-content: center;
    max-width: 600px;
    margin-top: 1.5rem;
    opacity: 0;
    animation: up .8s cubic-bezier(.22,1,.36,1) .3s forwards;
  }
 
  /* ── Base button ── */
  .cbtn {
    position: relative;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: .5rem;
    padding: .8rem 2rem;
    border: none;
    border-radius: 100px;
    font-family: 'Geist', sans-serif;
    font-size: .88rem;
    font-weight: 500;
    cursor: pointer;
    overflow: visible;
    transition: transform .2s cubic-bezier(.34,1.56,.64,1), box-shadow .2s;
    outline: none;
    letter-spacing: .01em;
  }
 
  .cbtn:hover  { transform: scale(1.05); }
  .cbtn:active { transform: scale(.96); }
 
  /* Variants */
  .cbtn-light {
    background: #f8fafc;
    color: #0f172a;
    box-shadow: 0 4px 20px rgba(255,255,255,0.15);
  }
  .cbtn-light:hover { box-shadow: 0 8px 32px rgba(255,255,255,0.25); }

  /* ── Ripple layer (CSS only) ── */
  .cbtn::after {
    content: '';
    position: absolute;
    inset: 0;
    border-radius: inherit;
    background: rgba(255,255,255,.2);
    opacity: 0;
    transform: scale(0);
    pointer-events: none;
  }
 
  .cbtn.fired::after {
    animation: ripple .5s ease-out forwards;
  }
 
  @keyframes ripple {
    to { opacity: 0; transform: scale(2.2); }
  }
 
  /* ── Confetti particle ── */
  .confetti {
    position: fixed;
    pointer-events: none;
    z-index: 999;
    border-radius: 2px;
    animation: confettiFall var(--dur) var(--ease) forwards;
  }
 
  @keyframes confettiFall {
    0%   { opacity: 1; transform: translate(0,0) rotate(0deg) scale(1); }
    100% { opacity: 0; transform: translate(var(--tx),var(--ty)) rotate(var(--tr)) scale(.3); }
  }
 

  @keyframes up {
    from { opacity:0; transform:translateY(12px); }
    to   { opacity:1; transform:translateY(0); }
  }
"""


const CONFETTI_JS_TEMPLATE = """
const SHAPES   = ['rect','circle','ribbon'];
  const EASINGS  = [
    'cubic-bezier(.22,1,.36,1)',
    'cubic-bezier(.4,0,.6,1)',
    'ease-out',
  ];
 
  export function burst(btn, e) {
    btn.classList.remove('fired');
    void btn.offsetWidth;
    btn.classList.add('fired');
 
    const colors = btn.dataset.colors.split(',');
    const rect   = btn.getBoundingClientRect();
    const ox     = rect.left + rect.width  / 2;
    const oy     = rect.top  + rect.height / 2;
    const count  = 28 + Math.floor(Math.random() * 14);
 
    for (let i = 0; i < count; i++) {
      const el     = document.createElement('div');
      el.className = 'confetti';
 
      const angle  = (Math.PI * 2 / count) * i + (Math.random() - .5) * .8;
      const dist   = 70 + Math.random() * 130;
      const tx     = Math.cos(angle) * dist;
      const ty     = Math.sin(angle) * dist - 60 - Math.random() * 60;
      const tr     = (Math.random() - .5) * 900 + 'deg';
      const dur    = (.6 + Math.random() * .6) + 's';
      const ease   = EASINGS[Math.floor(Math.random() * EASINGS.length)];
      const color  = colors[Math.floor(Math.random() * colors.length)];
      const shape  = SHAPES[Math.floor(Math.random() * SHAPES.length)];
      const size   = 5 + Math.random() * 8;
 
      el.style.cssText = `
        left:${ox}px; top:${oy}px;
        width:${shape === 'ribbon' ? size * 0.4 : size}px;
        height:${shape === 'ribbon' ? size * 2.5 : size}px;
        background:${color};
        border-radius:${shape === 'circle' ? '50%' : shape === 'ribbon' ? '1px' : '2px'};
        --tx:${tx}px; --ty:${ty}px; --tr:${tr};
        --dur:${dur}; --ease:${ease};
        transform:translate(-50%,-50%);
      `;
 
      document.body.appendChild(el);
      el.addEventListener('animationend', () => el.remove());
    }
  }
"""

const NIMBLE_TEMPLATE = """
# Package

version       = "0.1.0"
author        = "Your Name"
description   = "A new Jazzy Desktop App"
license       = "MIT"
srcDir        = "src"
bin           = @["app"]


# Dependencies

requires "nim >= 2.0.0"
requires "jazzy >= 0.4.4"
requires "jazzy_desktop >= """ & JAZZY_DESKTOP_VERSION & "\"\n"

const APP_NIM_TEMPLATE = """
import jazzy_desktop

proc sayHello(name: string, age: int): string {.expose.} =
  "Hello " & name

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
import { burst } from './lib/confetti'

function App() {
  const [msg, setMsg] = useState("Welcome to Jazzy Desktop")

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
      <div className="grid">
        <button className="cbtn cbtn-light" data-colors="#38bdf8,#818cf8,#c084fc,#e85d3a,#34d399" onClick={(e) => { burst(e.currentTarget, e); handleClick(); }}>🎉 Celebrate</button>
      </div>
    </div>
  )
}

export default App
"""

const VUE_TEMPLATE = """
<script setup>
import { ref } from 'vue'
import { jazzy } from './jazzy'
import { burst } from './lib/confetti'

const msg = ref("Welcome to Jazzy Desktop")

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
    <div class="grid">
      <button class="cbtn cbtn-light" data-colors="#38bdf8,#818cf8,#c084fc,#e85d3a,#34d399" @click="(e) => { burst(e.currentTarget, e); handleClick(); }">🎉 Celebrate</button>
    </div>
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
  import { burst } from './lib/confetti'

  let msg = "Welcome to Jazzy Desktop"

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
  <div class="grid">
    <button class="cbtn cbtn-light" data-colors="#38bdf8,#818cf8,#c084fc,#e85d3a,#34d399" on:click={(e) => { burst(e.currentTarget, e); handleClick(); }}>🎉 Celebrate</button>
  </div>
</main>
"""

const SOLID_TEMPLATE = """
import { createSignal } from 'solid-js'
import { jazzy } from './jazzy'
import './index.css'
import { burst } from './lib/confetti'

function App() {
  const [msg, setMsg] = createSignal("Welcome to Jazzy Desktop")

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
      <div class="grid">
        <button class="cbtn cbtn-light" data-colors="#38bdf8,#818cf8,#c084fc,#e85d3a,#34d399" onClick={(e) => { burst(e.currentTarget, e); handleClick(); }}>🎉 Celebrate</button>
      </div>
    </div>
  )
}

export default App
"""

const VANILLA_TEMPLATE = """
import './style.css'
import { jazzy } from './jazzy'
import { burst } from './lib/confetti'

document.querySelector('#app').innerHTML = `
  <div class="jazzy-container">
    <h1>Welcome to Jazzy Desktop</h1>
    <p id="msg">Welcome to Jazzy Desktop</p>
    <div class="grid">
      <button id="btn" class="cbtn cbtn-light" data-colors="#38bdf8,#818cf8,#c084fc,#e85d3a,#34d399">🎉 Celebrate</button>
    </div>
  </div>
`

document.querySelector('#btn').addEventListener('click', async (e) => {
  burst(e.currentTarget, e)
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
  let (createOut, createCode) = execCmdEx(shellCmd)
  if createCode != 0:
    styledEcho fgRed, "❌ Error scaffolding Vite project: ", createOut
    quit(1)

  if not dirExists("frontend"):
    styledEcho fgRed, "❌ Error: Failed to scaffold Vite project."
    quit(1)


  # Clean up default Vite boilerplate
  removeFile("frontend" / "src" / "lib" / "Counter.svelte")
  removeFile("frontend" / "src" / "components" / "HelloWorld.vue")
  removeFile("frontend" / "src" / "App.css")
  removeDir("frontend" / "src" / "assets")

  # Create Nim backend
  styledEcho fgMagenta, "⏳ Preparing backend skeleton..."
  createDir("src")

  writeFile("src" / "app.nim", APP_NIM_TEMPLATE)
  let nimbleName = projectName.replace("-", "_") & ".nimble"
  writeFile(nimbleName, NIMBLE_TEMPLATE)
  

  createDir("frontend" / "src" / "lib")
  writeFile("frontend" / "src" / "lib" / "confetti.js", CONFETTI_JS_TEMPLATE)
  
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

