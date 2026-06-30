// Jazzy Desktop JS client
// Forwards method calls to the Jazzy HTTP RPC server running at 127.0.0.1:8080
// Usage: const result = await jazzy.myNimFunction(arg1, arg2)

const RPC_BASE = "http://127.0.0.1:8080/rpc";

export const jazzy = new Proxy({}, {
  get(target, prop) {
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
