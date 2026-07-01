import types

proc selectFileDialog*(title: string, filters: seq[DialogFilter] = @[], forSave: bool = false): string =
  echo "Jazzy Desktop Dialogs: macOS selectFileDialog pending"
  return ""

proc showMessageBox*(title: string, message: string, msgType: MsgBoxType = mbInfo) =
  echo "Jazzy Desktop Dialogs: macOS implementation pending. Message: ", message
