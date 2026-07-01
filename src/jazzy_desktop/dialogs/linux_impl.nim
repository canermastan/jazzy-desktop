import types

proc selectFileDialog*(title: string, filters: seq[DialogFilter] = @[], forSave: bool = false): string =
  echo "Jazzy Desktop Dialogs: Linux selectFileDialog pending"
  return ""

proc showMessageBox*(title: string, message: string, msgType: MsgBoxType = mbInfo) =
  echo "Jazzy Desktop Dialogs: Linux implementation pending. Message: ", message
