// Jazzy Desktop JS client
// Forwards method calls to the Jazzy HTTP RPC server running at 127.0.0.1:8080
// Usage: const result = await jazzy.myNimFunction(arg1, arg2)

const RPC_BASE = "http://127.0.0.1:8080/rpc";
const WS_URL = "ws://127.0.0.1:8080/_jazzy/events";

const listeners = {};
let ws = null;

function connectWs() {
  ws = new WebSocket(WS_URL);

  ws.onmessage = (event) => {
    try {
      const data = JSON.parse(event.data);
      const name = data.event;
      const payload = data.payload;
      if (listeners[name]) {
        listeners[name].forEach((cb) => {
          try { cb(payload); } catch (e) { console.error(e); }
        });
      }
    } catch (err) {
      console.error("Failed to parse WebSocket message:", err);
    }
  };

  ws.onclose = () => {
    // Reconnect after 1 second
    setTimeout(connectWs, 1000);
  };

  ws.onerror = (err) => {
    console.error("WebSocket error:", err);
    ws.close();
  };
}

// Connect automatically on client initialization
if (typeof window !== "undefined") {
  connectWs();
}

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
    if (prop in target) {
      return target[prop];
    }
    if (typeof prop === "symbol" || prop.startsWith("_")) return undefined;

    return async (...args) => {
      const response = await fetch(`${RPC_BASE}/${prop}`, {
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
