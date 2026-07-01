import { useState, useEffect } from "react";
import { jazzy } from "./jazzy";
import "./App.css";

function App() {
  const [response, setResponse] = useState("Click the button to call Nim");
  const [progress, setProgress] = useState(0);
  const [progressRunning, setProgressRunning] = useState(false);

  useEffect(() => {
    const handleProgress = (data) => {
      setProgress(data.percent);
    };
    jazzy.on("progress", handleProgress);
    return () => {
      jazzy.off("progress", handleProgress);
    };
  }, []);

  const startProgressTask = async () => {
    setProgress(0);
    setProgressRunning(true);
    setResponse("Running background progress task...");
    try {
      await jazzy.runProgressTask();
    } catch (err) {
      setResponse("Progress task error: " + err.message);
    } finally {
      setProgressRunning(false);
    }
  };

  const handlePickFile = async () => {
    setResponse("Opening native file picker...");
    try {
      const filePath = await jazzy.pickFile();
      setResponse(filePath ? `Selected File: ${filePath}` : "File selection canceled.");
    } catch (err) {
      setResponse("Error: " + err.message);
    }
  };

  const handleShowAlert = async () => {
    setResponse("Showing native alert...");
    try {
      await jazzy.showAlert("Hello from Jazzy Desktop Native Dialog!");
      setResponse("Alert dismissed.");
    } catch (err) {
      setResponse("Error: " + err.message);
    }
  };

  const handleReadClipboard = async () => {
    setResponse("Reading clipboard...");
    try {
      const text = await jazzy.readCb();
      setResponse(text ? `Clipboard contents: ${text}` : "Clipboard is empty or contains non-text data.");
    } catch (err) {
      setResponse("Error: " + err.message);
    }
  };

  const handleWriteClipboard = async () => {
    try {
      const success = await jazzy.writeCb("Hello from Jazzy React App!");
      if (success) {
        setResponse("Successfully wrote to native clipboard! (Try pasting somewhere)");
      } else {
        setResponse("Failed to write to clipboard.");
      }
    } catch (err) {
      setResponse("Error: " + err.message);
    }
  };

  const handleInitTray = async () => {
    try {
      await jazzy.showTray("Jazzy Desktop App");
    } catch (err) {
      setResponse("Error: " + err.message);
    }
  };

  const handleOpenLink = async () => {
    try {
      await jazzy.openExternalLink("https://github.com");
      setResponse("Opened Github in your default browser!");
    } catch (err) {
      setResponse("Error: " + err.message);
    }
  };

  const handleWriteLog = async () => {
    try {
      await jazzy.writeLog("Hello from React!");
      setResponse("Successfully wrote to jazzy.log file!");
    } catch (err) {
      setResponse("Error: " + err.message);
    }
  };

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

  const changeTitle = () => {
    if (window.jazzySetTitle) {
      window.jazzySetTitle("Jazzy App - New Title!");
    } else {
      setResponse("window.jazzySetTitle is not available");
    }
  };

  const resizeWindow = () => {
    if (window.jazzySetSize) {
      window.jazzySetSize(800, 600);
    } else {
      setResponse("window.jazzySetSize is not available");
    }
  };

  const closeWindow = () => {
    if (window.jazzyClose) {
      window.jazzyClose();
    } else {
      setResponse("window.jazzyClose is not available");
    }
  };

  const [logMsg, setLogMsg] = useState("");
  const [logs, setLogs] = useState([]);

  const handleSaveLog = async () => {
    try {
      const success = await jazzy.saveLog(logMsg);
      if (success) {
        setResponse("Log saved successfully!");
        setLogMsg("");
        handleGetLogs();
      }
    } catch (e) {
      setResponse("Error saving log: " + e.message);
    }
  };

  const handleGetLogs = async () => {
    try {
      const res = await jazzy.getLogs();
      setLogs(res);
    } catch (e) {
      setResponse("Error getting logs: " + e.message);
    }
  };

  return (
    <div className="App" style={{ padding: "2rem", textAlign: "center" }}>
      <h1>Jazzy Desktop + React + Vite</h1>
      <p>Click the button to call a Nim function over HTTP RPC.</p>

      {/* Progress Bar UI */}
      {(progressRunning || progress > 0) && (
        <div style={{ margin: "2rem auto", width: "100%", maxWidth: "600px" }}>
          <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "5px" }}>
            <span>Progress Task Status</span>
            <span>{progress}%</span>
          </div>
          <div style={{ width: "100%", height: "20px", backgroundColor: "#333", borderRadius: "10px", overflow: "hidden" }}>
            <div style={{ width: `${progress}%`, height: "100%", backgroundColor: "#4caf50", transition: "width 0.2s ease-in-out" }}></div>
          </div>
        </div>
      )}

      <div style={{ margin: "2rem", display: "flex", justifyContent: "center", gap: "10px", flexWrap: "wrap" }}>
        <button
          onClick={startProgressTask}
          disabled={progressRunning}
          style={{
            padding: "10px 20px",
            fontSize: "1.2rem",
            cursor: progressRunning ? "not-allowed" : "pointer",
            backgroundColor: "#e91e63",
            color: "white",
            border: "none",
            borderRadius: "8px",
            opacity: progressRunning ? 0.6 : 1,
          }}
        >
          {progressRunning ? "Running..." : "Start Progress Task (WS)"}
        </button>
        <button
          onClick={handlePickFile}
          style={{
            padding: "10px 20px",
            fontSize: "1.2rem",
            cursor: "pointer",
            backgroundColor: "#009688",
            color: "white",
            border: "none",
            borderRadius: "8px",
          }}
        >
          Pick File (Native)
        </button>
        <button
          onClick={handleShowAlert}
          style={{
            padding: "10px 20px",
            fontSize: "1.2rem",
            cursor: "pointer",
            backgroundColor: "#FF5722",
            color: "white",
            border: "none",
            borderRadius: "8px",
          }}
        >
          Show Alert (Native)
        </button>
        <button
          onClick={handleReadClipboard}
          style={{
            padding: "10px 20px",
            fontSize: "1.2rem",
            cursor: "pointer",
            backgroundColor: "#795548",
            color: "white",
            border: "none",
            borderRadius: "8px",
          }}
        >
          Read Clipboard (Native)
        </button>
        <button
          onClick={handleWriteClipboard}
          style={{
            padding: "10px 20px",
            fontSize: "1.2rem",
            cursor: "pointer",
            backgroundColor: "#607D8B",
            color: "white",
            border: "none",
            borderRadius: "8px",
          }}
        >
          Write to Clipboard
        </button>
        <button
          onClick={handleInitTray}
          style={{
            padding: "10px 20px",
            fontSize: "1.2rem",
            cursor: "pointer",
            backgroundColor: "#9C27B0",
            color: "white",
            border: "none",
            borderRadius: "8px",
          }}
        >
          Create Tray Icon
        </button>
        <button
          onClick={handleOpenLink}
          style={{
            padding: "10px 20px",
            fontSize: "1.2rem",
            cursor: "pointer",
            backgroundColor: "#2196F3",
            color: "white",
            border: "none",
            borderRadius: "8px",
          }}
        >
          Open GitHub in Browser
        </button>
        <button
          onClick={handleWriteLog}
          style={{
            padding: "10px 20px",
            fontSize: "1.2rem",
            cursor: "pointer",
            backgroundColor: "#607D8B",
            color: "white",
            border: "none",
            borderRadius: "8px",
          }}
        >
          Write to Log File
        </button>
        <button
          onClick={() => window.jazzyWindowCenter && window.jazzyWindowCenter()}
          style={{
            padding: "10px 20px",
            fontSize: "1.2rem",
            cursor: "pointer",
            backgroundColor: "#3F51B5",
            color: "white",
            border: "none",
            borderRadius: "8px",
          }}
        >
          Center Window
        </button>
        <button
          onClick={() => window.jazzyWindowMinimize && window.jazzyWindowMinimize()}
          style={{
            padding: "10px 20px",
            fontSize: "1.2rem",
            cursor: "pointer",
            backgroundColor: "#009688",
            color: "white",
            border: "none",
            borderRadius: "8px",
          }}
        >
          Minimize
        </button>
        <button
          onClick={() => window.jazzyWindowMaximize && window.jazzyWindowMaximize()}
          style={{
            padding: "10px 20px",
            fontSize: "1.2rem",
            cursor: "pointer",
            backgroundColor: "#FF9800",
            color: "white",
            border: "none",
            borderRadius: "8px",
          }}
        >
          Maximize
        </button>
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
          Save Theme
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
          Save User
        </button>
        <button
          onClick={changeTitle}
          style={{
            padding: "10px 20px",
            fontSize: "1.2rem",
            cursor: "pointer",
            backgroundColor: "#2196F3",
            color: "white",
            border: "none",
            borderRadius: "8px",
          }}
        >
          Change Title
        </button>
        <button
          onClick={resizeWindow}
          style={{
            padding: "10px 20px",
            fontSize: "1.2rem",
            cursor: "pointer",
            backgroundColor: "#9C27B0",
            color: "white",
            border: "none",
            borderRadius: "8px",
          }}
        >
          Resize Window
        </button>
        <button
          onClick={closeWindow}
          style={{
            padding: "10px 20px",
            fontSize: "1.2rem",
            cursor: "pointer",
            backgroundColor: "#F44336",
            color: "white",
            border: "none",
            borderRadius: "8px",
          }}
        >
          Close App
        </button>
      </div>

      <div style={{ margin: "2rem auto", padding: "20px", border: "1px solid #4caf50", borderRadius: "8px", maxWidth: "600px", backgroundColor: "#1e1e1e", color: "white" }}>
        <h3>Jazzy ORM Database Test</h3>
        <div style={{ display: "flex", gap: "10px", justifyContent: "center", marginBottom: "10px" }}>
          <input 
            type="text" 
            value={logMsg} 
            onChange={(e) => setLogMsg(e.target.value)} 
            placeholder="Enter log message" 
            style={{ padding: "8px", borderRadius: "4px", border: "1px solid #ccc", flex: 1 }}
          />
          <button onClick={handleSaveLog} style={{ padding: "8px 16px", backgroundColor: "#4caf50", color: "white", border: "none", borderRadius: "4px", cursor: "pointer" }}>Save to DB</button>
          <button onClick={handleGetLogs} style={{ padding: "8px 16px", backgroundColor: "#2196F3", color: "white", border: "none", borderRadius: "4px", cursor: "pointer" }}>Load Logs</button>
        </div>
        {logs.length > 0 && (
          <ul style={{ textAlign: "left", paddingLeft: "20px" }}>
            {logs.map(log => (
              <li key={log.id}>
                <strong>[{log.created_at}]</strong> {log.message}
              </li>
            ))}
          </ul>
        )}
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
