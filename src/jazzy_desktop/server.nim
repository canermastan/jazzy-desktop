import jazzy
import jazzy/core/middlewares as jmw
import os

type ServerConfig* = object
  port*: int
  address*: string
  prodDir*: string

var serverThread*: Thread[ServerConfig]

proc runJazzyServer*(cfg: ServerConfig) {.thread.} =
  {.cast(gcsafe).}:
    if cfg.prodDir.len > 0 and dirExists(cfg.prodDir):
      Jazzy.static(cfg.prodDir, "/")

    Jazzy.use(jmw.cors(allowedOrigin = "*"))
    Jazzy.serve(cfg.port, cfg.address)
