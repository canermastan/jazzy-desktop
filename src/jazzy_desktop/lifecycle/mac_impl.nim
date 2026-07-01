import std/[os, nativesockets, asyncdispatch]

proc enforceSingleInstance*(appId: string) =
  # MacOS is Unix-based, so we can use the exact same Unix socket approach as Linux.
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
  else:
    echo "Warning: Could not bind single instance lock."
