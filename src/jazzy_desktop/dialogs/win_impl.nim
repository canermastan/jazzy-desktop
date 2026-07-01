import strutils, types

type
  HWND = int
  HINSTANCE = int
  LPCWSTR = WideCString
  LPWSTR = WideCString
  DWORD = int32
  WORD = int16
  UINT = int32
  LPARAM = int

  OPENFILENAMEW {.pure, final.} = object
    lStructSize: DWORD
    hwndOwner: HWND
    hInstance: HINSTANCE
    lpstrFilter: LPCWSTR
    lpstrCustomFilter: LPWSTR
    nMaxCustFilter: DWORD
    nFilterIndex: DWORD
    lpstrFile: LPWSTR
    nMaxFile: DWORD
    lpstrFileTitle: LPWSTR
    nMaxFileTitle: DWORD
    lpstrInitialDir: LPCWSTR
    lpstrTitle: LPCWSTR
    Flags: DWORD
    nFileOffset: WORD
    nFileExtension: WORD
    lpstrDefExt: LPCWSTR
    lCustData: LPARAM
    lpfnHook: pointer
    lpTemplateName: LPCWSTR
    pvReserved: pointer
    dwReserved: DWORD
    FlagsEx: DWORD

const
  OFN_FILEMUSTEXIST = 0x00001000'i32
  OFN_PATHMUSTEXIST = 0x00000800'i32
  OFN_OVERWRITEPROMPT = 0x00000002'i32
  OFN_HIDEREADONLY = 0x00000004'i32

  MB_OK = 0x00000000'i32
  MB_ICONERROR = 0x00000010'i32
  MB_ICONQUESTION = 0x00000020'i32
  MB_ICONWARNING = 0x00000030'i32
  MB_ICONINFORMATION = 0x00000040'i32

proc GetOpenFileNameW(lpofn: ptr OPENFILENAMEW): bool {.stdcall, dynlib: "comdlg32.dll", importc: "GetOpenFileNameW".}
proc GetSaveFileNameW(lpofn: ptr OPENFILENAMEW): bool {.stdcall, dynlib: "comdlg32.dll", importc: "GetSaveFileNameW".}
proc MessageBoxW(hWnd: HWND, lpText: LPCWSTR, lpCaption: LPCWSTR, uType: UINT): int32 {.stdcall, dynlib: "user32.dll", importc: "MessageBoxW".}

proc buildWinFilter(filters: seq[DialogFilter]): seq[int16] =
  var res: seq[int16] = @[]
  if filters.len == 0: return res
  for f in filters:
    let wName = newWideCString(f.name)
    var i = 0
    while int(wName[i]) != 0:
      res.add(cast[int16](wName[i]))
      inc(i)
    res.add(0'i16)
    
    let wExt = newWideCString(f.extensions)
    i = 0
    while int(wExt[i]) != 0:
      res.add(cast[int16](wExt[i]))
      inc(i)
    res.add(0'i16)
  res.add(0'i16)
  return res

proc selectFileDialog*(title: string, filters: seq[DialogFilter] = @[], forSave: bool = false): string =
  var ofn: OPENFILENAMEW
  ofn.lStructSize = cast[DWORD](sizeof(OPENFILENAMEW))
  
  var fileName = newWideCString(newString(260))
  ofn.lpstrFile = fileName
  ofn.nMaxFile = 260
  
  var wTitle = newWideCString(title)
  ofn.lpstrTitle = wTitle
  
  var filterBuf = buildWinFilter(filters)
  if filterBuf.len > 0:
    ofn.lpstrFilter = cast[LPCWSTR](filterBuf[0].addr)
  
  if forSave:
    ofn.Flags = OFN_PATHMUSTEXIST or OFN_OVERWRITEPROMPT or OFN_HIDEREADONLY
    if GetSaveFileNameW(addr ofn): return $ofn.lpstrFile
  else:
    ofn.Flags = OFN_PATHMUSTEXIST or OFN_FILEMUSTEXIST or OFN_HIDEREADONLY
    if GetOpenFileNameW(addr ofn): return $ofn.lpstrFile
    
  return ""

proc showMessageBox*(title: string, message: string, msgType: MsgBoxType = mbInfo) =
  var flags = MB_OK
  case msgType
  of mbInfo: flags = flags or MB_ICONINFORMATION
  of mbWarning: flags = flags or MB_ICONWARNING
  of mbError: flags = flags or MB_ICONERROR
  of mbQuestion: flags = flags or MB_ICONQUESTION

  discard MessageBoxW(0, newWideCString(message), newWideCString(title), flags)
