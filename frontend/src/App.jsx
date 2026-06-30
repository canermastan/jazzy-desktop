import { useState } from "react";
import { jazzy } from "./jazzy";
import "./App.css";

function App() {
  const [response, setResponse] = useState("Click the button to call Nim");

  const callNimBackend = async () => {
    setResponse("Loading...");
    try {
      const result = await jazzy.sayHello("Caner", 25);
      setResponse(result);
    } catch (err) {
      setResponse("Error: " + err.message);
    }
  };

  const callSaveTheme = async () => {
    setResponse("Loading...");
    try {
      const result = await jazzy.saveUserSettings("dark-mode");
      setResponse("Saved theme success: " + result);
    } catch (err) {
      setResponse("Error: " + err.message);
    }
  };

  const callSaveUser = async () => {
    setResponse("Loading...");
    try {
      const user = { id: 1, name: "Alice", roles: ["admin", "editor"] };
      const result = await jazzy.saveUser(user);
      setResponse("Saved user: " + JSON.stringify(result));
    } catch (err) {
      setResponse("Error: " + err.message);
    }
  };

  return (
    <div className="App" style={{ padding: "2rem", textAlign: "center" }}>
      <h1>Jazzy Desktop + React + Vite</h1>
      <p>Click the button to call a Nim function over HTTP RPC.</p>

      <div style={{ margin: "2rem", display: "flex", justifyContent: "center", gap: "10px" }}>
        <button
          onClick={callNimBackend}
          style={{
            padding: "10px 20px",
            fontSize: "1.2rem",
            cursor: "pointer",
            backgroundColor: "#646cff",
            color: "white",
            border: "none",
            borderRadius: "8px",
          }}
        >
          Call sayHello()
        </button>
        <button
          onClick={callSaveTheme}
          style={{
            padding: "10px 20px",
            fontSize: "1.2rem",
            cursor: "pointer",
            backgroundColor: "#4caf50",
            color: "white",
            border: "none",
            borderRadius: "8px",
          }}
        >
          Save Theme (Test Context)
        </button>
        <button
          onClick={callSaveUser}
          style={{
            padding: "10px 20px",
            fontSize: "1.2rem",
            cursor: "pointer",
            backgroundColor: "#ff9800",
            color: "white",
            border: "none",
            borderRadius: "8px",
          }}
        >
          Save User (Test Object)
        </button>
      </div>

      <div
        style={{
          padding: "20px",
          backgroundColor: "#2a2a2a",
          color: "white",
          borderRadius: "8px",
          borderLeft: "4px solid #646cff",
          display: "inline-block",
          minWidth: "300px",
        }}
      >
        <h3>Response from Nim:</h3>
        <p>{response}</p>
      </div>
    </div>
  );
}

export default App;
