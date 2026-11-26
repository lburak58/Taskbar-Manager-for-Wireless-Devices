' Taskbar Manager for Wireless Devices uygulamasini konsol penceresi gostermeden baslatir. Argumanlar (ornegin -Demo) aktarilir.
Set sh = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
dir = fso.GetParentFolderName(WScript.ScriptFullName)
args = ""
For i = 0 To WScript.Arguments.Count - 1
    args = args & " " & WScript.Arguments(i)
Next
cmd = "powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & dir & "\TaskbarManagerForWirelessDevices.ps1""" & args
sh.Run cmd, 0, False
