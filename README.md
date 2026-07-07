<div align="center">
  <img src="logo.png" alt="Jazzy Desktop" width="150" />
  <h1>Jazzy Desktop</h1>
  <p><strong>Build modern desktop applications with Nim and your favourite web stack.</strong></p>
  <p><em>The desktop application framework for the Nim ecosystem — powered by <a href="https://canermastan.github.io/jazzyframework/">Jazzy Framework</a> under the hood.</em></p>

  <p>
    <a href="https://nim-lang.org/"><img src="https://img.shields.io/badge/Nim-2.0%2B-FFE953?style=flat-square&logo=nim&logoColor=000" alt="Nim 2.0+"></a>
    <img src="https://img.shields.io/badge/version-0.1.0-blueviolet?style=flat-square" alt="version">
    <img src="https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-informational?style=flat-square" alt="Platform">
    <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="MIT License"></a>
  </p>

  <p>
    <a href="#why-jazzy-desktop">Why Jazzy?</a> •
    <a href="#features">Features</a> •
    <a href="#quick-start">Quick Start</a> •
    <a href="#core-concepts">Core Concepts</a> •
    <a href="#native-os-apis">Native OS APIs</a> •
    <a href="#web-mode">Web Mode</a> •
    <a href="#roadmap">Roadmap</a>
  </p>
</div>

---

## Why Jazzy Desktop?

The Nim ecosystem has GUI libraries — but they all make you think in widgets, layouts, and signals. It's 2026. Your users expect the web. **Jazzy Desktop** lets you build with the tools you already know: React, Vue, Svelte, plain HTML — anything that runs in a browser — while your backend is pure, compiled, blazing-fast Nim.

|  | NiGui | libui-ng (nim-libui) | fidget | **Jazzy Desktop** |
|---|---|---|---|---|
| **UI Model** | Native widgets | Native widgets | OpenGL canvas | **Web (HTML/CSS/JS)** |
| **Frontend** | Nim only | Nim only | Nim only | **React / Vue / Svelte / anything** |
| **Styling** | OS-native | OS-native | Custom | **Full CSS, animations, glassmorphism** |
| **IPC** | — | — | — | **Zero-config RPC + WebSockets** |
| **Web Deploy** | ✗ | ✗ | ✗ | **✓ — same binary, zero changes** |
| **Hot-Reload** | ✗ | ✗ | ✗ | **✓** |

Native GUI toolkits are powerful, but they come with constraints. Jazzy Desktop removes those constraints: your UI is a first-class web application backed by a native Nim process, communicating over a local [Jazzy](https://canermastan.github.io/jazzyframework/) HTTP server. You get the rendering power of the browser, the raw speed of Nim, and a zero-config bridge between them.

---

## Features

### ✨ Zero-Config RPC
Write a Nim function, annotate it with `{.expose.}`, and call it from JavaScript like a local function. The macro takes care of routing, type validation, and serialization automatically.

### ⚡ Blazing-Fast Native Binary
Your backend compiles to native machine code via Nim's C/C++ transpiler. Tiny memory footprint, instant startup time.

### 🔄 Two-Way Real-Time Events
Push data from Nim to your frontend at any time using the built-in WebSocket event bus — no polling, no complexity.

### 🖥️ Full Native OS Integration
Window management, system tray, native file dialogs, clipboard, single-instance lock, and Windows 11 Mica glass effect — all accessible from JavaScript.

### 🌐 Deploy as a Web App
Compile your desktop app into a pure web server with the `--web` flag. **Zero code changes required.**

### 🗄️ Built-in Local Settings Store
A built-in `store.nim` module persists user preferences (theme, language, window size…) in OS-appropriate config directories — `AppData/Roaming` on Windows, `Library/Application Support` on macOS, `~/.config` on Linux.

### 🔥 Hot-Reload Development
`jazzyd dev` watches both your Nim backend and Vite frontend simultaneously, restarting only what changed.

---

## Quick Start

### Prerequisites

- [Nim](https://nim-lang.org/install.html) `>= 2.0`
- [Node.js](https://nodejs.org/) (for the Vite frontend)
- MinGW-w64 (Windows) or a standard C++ toolchain

### 1. Install

```bash
nimble install jazzy_desktop
```

### 2. Create a New Project

```bash
jazzyd new my-awesome-app
cd my-awesome-app
```

### 3. Start Development

```bash
jazzyd dev
```

Both the Nim backend and the Vite frontend start together with Hot-Reload. Edit any file and see changes reflected instantly.

### 4. Build for Production

```bash
jazzyd build
```

Produces a **single, self-contained executable** with all frontend assets embedded inside via Nim's compile-time VFS.

---

## Core Concepts

### The `{.expose.}` Macro — RPC Made Trivial

This is the heart of Jazzy Desktop. Any Nim `proc` annotated with `{.expose.}` is automatically registered as an RPC endpoint callable from JavaScript — no routes, no `fetch`, no boilerplate.

**Backend** (`src/app.nim`):
```nim
import jazzy_desktop

# This function becomes directly callable from JavaScript.
proc greet(name: string, age: int): string {.expose.} =
  return "Hello " & name & "! You are " & $age & " years old."

# Pass `ctx: Context` to access DB, headers, sessions.
# The macro knows not to expect `ctx` from the JS payload.
proc saveSettings(ctx: Context, theme: string): bool {.expose.} =
  storeSet("theme", %theme)
  return true

startDesktopApp(
  title   = "My Awesome App",
  width   = 1200,
  height  = 800,
  devUrl  = "http://localhost:5173",
  prodDir = "../frontend/dist"
)
```

**Frontend** (`frontend/src/App.jsx`):
```javascript
import { jazzy } from './jazzy';

// Calling Nim feels exactly like calling a local async function.
const message = await jazzy.greet("Caner", 25);
// → "Hello Caner! You are 25 years old."

await jazzy.saveSettings("dark-mode");
```

---

### Two-Way Events — Pushing Data from Nim to the Frontend

Emit real-time data from a background Nim thread directly to your React components via the built-in WebSocket event bus.

**Nim side:**
```nim
import jazzy_desktop/events

proc runHeavyTask() {.expose.} =
  for i in 1..100:
    emit("progress", %*{"value": i})
    sleep(50)
```

**JavaScript side:**
```javascript
import { jazzy } from './jazzy';

// Subscribe on component mount
jazzy.on("progress", (data) => {
  setProgress(data.value);
});

// Clean up on unmount
jazzy.off("progress");
```

---

## Native OS APIs

All native capabilities are exposed to your JavaScript frontend via the `window`-level bridge injected by Jazzy's WebView layer.

### 💻 Window Management

```javascript
jazzyWindowMinimize();  // Minimize to taskbar
jazzyWindowMaximize();  // Maximize window
jazzyWindowRestore();   // Restore from maximized state
jazzyWindowHide();      // Hide window and taskbar entry
jazzyWindowShow();      // Bring back to foreground
jazzyWindowCenter();    // Center on the current monitor
```

Build fully **frameless windows** with native drag support and Windows 11 **Mica** backdrop blur effect — no additional configuration required.

### 📂 Native File Dialogs

```nim
import jazzy_desktop/dialogs

# Open dialog — pick an existing file
let file = selectFileDialog(
  "Choose an Image",
  @[DialogFilter(name: "Images", extensions: "*.png;*.jpg;*.webp")],
  multiSelect = false,
  forSave     = false
)

# Save dialog — choose where to write a new file
let dest = selectFileDialog(
  "Save Export",
  @[DialogFilter(name: "PDF", extensions: "*.pdf")],
  multiSelect = false,
  forSave     = true
)
```

Supports open dialogs, save dialogs, folder pickers, and native OS message boxes.

### 🔔 System Tray

Add your app to the system tray notification area (bottom-right corner on Windows) with a fully native right-click context menu, driven from `jazzy_desktop/tray`.

### 📋 Clipboard & Browser

```nim
import jazzy_desktop/clipboard
import jazzy_desktop/browser

writeClipboard("Copied from Nim!")
let text = readClipboard()

# Open in the user's default browser, not inside the WebView
openBrowser("https://nim-lang.org")
```

### 🔒 Single Instance Lock

```nim
enforceSingleInstance()
# Prevents duplicate app launches.
# Focuses the existing window instead of opening a second one.
```

---

## Web Mode

Jazzy Desktop is built on top of the **[Jazzy Framework](https://canermastan.github.io/jazzyframework/)** — a fast, production-ready Nim web framework. When you build a Jazzy Desktop app, a local Jazzy HTTP server runs in the background, serving your RPC endpoints, handling WebSocket events, and powering the optional ORM layer.

This means your app can be deployed as a standard web application with a single CLI flag — without touching your application code.

```bash
# Develop in the browser (no native window opened)
jazzyd dev --web

# Build a standalone web server binary for deployment
jazzyd build --web
```

The resulting binary can run on a Linux VPS, listen on port `8080`, and serve behind Nginx like any conventional web app. Your desktop UI and business logic are shared 100% between both targets.

---

## Project Structure

```
my-app/
├── frontend/               # Vite-powered frontend (React / Vue / Svelte)
│   ├── src/
│   │   ├── App.jsx
│   │   └── jazzy.js        # RPC client (JS Proxy, auto-generated)
│   └── vite.config.ts
│
├── src/
│   └── app.nim             # Entry point — expose procs, start the app
│
└── my-app.nimble
```

---

## Configuration

```nim
startDesktopApp(
  title           = "My App",
  width           = 1200,
  height          = 800,
  devUrl          = "http://localhost:5173",
  prodDir         = "../frontend/dist",
  port            = 7654,   # Internal HTTP server port (default: 7654)
  maxUploadSizeMb = 50      # File upload limit in MB (default: 10)
)
```
---

## Roadmap

- [x] Zero-config `{.expose.}` RPC macro with type validation
- [x] Native WebView2 / WebKit integration
- [x] Window management API (minimize, maximize, center, frameless, Mica)
- [x] System Tray with native context menus
- [x] Native file open/save/folder dialogs
- [x] Clipboard & external browser support
- [x] Single-instance lock
- [x] Two-way WebSocket event bus
- [x] Hot-reload dev server (`jazzyd dev`)
- [x] Single-EXE production build with embedded frontend (VFS)
- [x] `--web` flag for zero-change web deployment
- [x] Built-in local settings store (`store.nim`)
- [x] `jazzyd new` project scaffolding CLI
- [ ] macOS full support (native window controls, app bundle, code signing)
- [ ] OS-level dark/light mode detection API
- [ ] Native notification (OS toast / notification center)
- [ ] Global keyboard shortcuts (system-wide hotkeys)
- [ ] Screen & multi-monitor info API
- [ ] App auto-updater integration

---

## Contributing

Jazzy Desktop is a young project and there is meaningful work ahead. Contributions are very welcome — especially around macOS support, new native APIs, and async macro improvements. Check the roadmap above for good first-contribution candidates.

---

<div align="center">
  <img src="logo.png" alt="Jazzy Desktop" width="52" /><br/>
  <sub>
    Powered by <a href="https://canermastan.github.io/jazzyframework/">Jazzy Framework</a> &nbsp;·&nbsp;
    Built with ❤️ and <a href="https://nim-lang.org/">Nim</a> &nbsp;·&nbsp;
    <a href="LICENSE">MIT License</a>
  </sub>
</div>
