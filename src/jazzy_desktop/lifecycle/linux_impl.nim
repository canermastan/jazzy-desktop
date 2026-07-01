import std/[os, nativesockets, asyncdispatch]

proc enforceSingleInstance*(appId: string) =
  # Uses a Unix domain socket in /tmp/ to ensure a single instance.
  let socketPath = getTempDir() / (appId & ".sock")
  
  let fd = createNativeSocket(AF_UNIX, SOCK_STREAM, 0)
  if fd == osInvalidSocket: return
  
  # Try to connect. If it succeeds, another instance is running.
  if connect(fd, socketPath) == 0:
    echo "Another instance of " & appId & " is already running. Exiting..."
    close(fd)
    quit(0)
  close(fd)
  
  # Otherwise, we are the first instance. Bind and listen.
  # Cleanup old stale socket if it exists but wasn't listening.
  if fileExists(socketPath): removeFile(socketPath)
  
  let listenFd = createNativeSocket(AF_UNIX, SOCK_STREAM, 0)
  if bindUnix(listenFd, socketPath) == 0:
    discard listen(listenFd)
    # Start a background async loop to keep the socket alive
    # We do not need to accept connections, just hold the binding.
    # In a full impl, we could read from it to "bring to front".
  else:
    echo "Warning: Could not bind single instance lock."
