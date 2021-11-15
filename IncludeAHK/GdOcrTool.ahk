;=======================================================================================
; GdOcrTool.ahk is an AutoHotkey (v1.1) script to enhance the GoldenDict with OCR
; functionality using Capture2Text.
; Written by Johnny Van, 2021/11/13
; Updated 2021/11/14, add support for MDict, Eudic
;=======================================================================================
; Auto-execution section.

#NoEnv
#SingleInstance, force
SendMode Input
SetWorkingDir %A_ScriptDir%
SetBatchLines -1
CoordMode, ToolTip, Screen
DetectHiddenWindows, On

Global GoldenDictFileName := "d:\PortableApps\PortableApps\GoldenDict\GoldenDict.exe"
Global MdictFileName := "C:\Program Files\MDictPC\MDict.exe"
Global EudicFileName := "C:\Program Files (x86)\eudic\eudic.exe"
Global Capture2TextFileName := "c:\Apps\Capture2Text\Capture2Text.exe"
Global DictSelected := "GoldenDict"  ; Dictionary selected: "GoldenDict", "MDict", "Eudic"
Global CaptureMode := "NoCapture"  ; Capture mode: "NoCapture", "SingleWordCapture", "BoxCapture"
Global CaptureCount := 0
Global LineCaptured := ""
Global ForwardLineCaptured := ""
Global Timeout := 8000  ; Timeout in millisecond. Abort capture if the timeout has expired.
Global StartTime, EndTime

Main()

;=======================================================================================
;

Main() {
    Menu, Tray, Icon, shell32.dll, 172

    If !FileExist(Capture2TextFileName) {
        MsgBox, 48, Warning, Capture2Text.exe not found! Exiting program...
        ExitApp
    }

    Switch DictSelected {
        Case "GoldenDict":
            If !FileExist(GoldenDictFileName) {
                MsgBox, 48, Warning, GoldenDict.exe not found! Exiting program...
                ExitApp
            } Else {
;                Run % GoldenDictFileName
            }
        Case "MDict":
            If !FileExist(MDictFileName) {
                MsgBox, 48, Warning, MDict.exe not found! Exiting program...
                ExitApp
            } Else {
                Run % MDictFileName
            }
        Case "Eudic":
            If !FileExist(EudicFileName) {
                MsgBox, 48, Warning, eudic.exe not found! Exiting program...
                ExitApp
            } Else {
                Run % EudicFileName
            }
    }

    Run % Capture2TextFileName
    OnClipboardChange("ClipboardChange")
    Return
}

; Monitoring clipboard change.
ClipboardChange(Type) {
; 0 = Clipboard is now empty.
; 1 = Clipboard contains something that can be expressed as text (this includes files copied from an Explorer window).
; 2 = Clipboard contains something entirely non-text such as a picture.
    If (Type != 1) {
        Return
    }

    Switch CaptureMode {
        Case "NoCapture":
            Return
        Case "SingleWordCapture":
            SingleWordCaptureHandler()
        Case "BoxCapture":
            BoxCaptureHandler()
    }

    Return
}

SingleWordCaptureHandler() {
    CaptureCount += 1
    Switch CaptureCount {
        Case 1:
            ; ClipboardChange invoked by line capture.
            LineCaptured := Clipboard
            StartForwardLineCapture()
        Case 2:
            ; ClipboardChange invoked by forward line capture.
            ResetCaptureMode()
            ForwardLineCaptured := Clipboard
            ArrayTemp := ExtractSingleWord()
            SearchTerm := ArrayTemp[1]
            ExtractError := ArrayTemp[2]
            If !ExtractError {
                SendToSelectedDict(SearchTerm)
            }
        Default:
            ResetCaptureMode()
    }
    Return
}

BoxCaptureHandler() {
    ResetCaptureMode()
    SendToSelectedDict(Clipboard)
    Return
}

; Extract the single word from the two-step OCR.
ExtractSingleWord() {
    ExtractError := 0

    ForwardLineCapturedPos := InStr(LineCaptured, ForwardLineCaptured)
    If (ForwardLineCapturedPos == 0) {
        ExtractError := 1
        ToolTip, Recognition failed.
        SetTimer, TurnOffToolTip, -1000
        Return ["", ExtractError]
    }

    FrontString := SubStr(LineCaptured, 1, ForwardLineCapturedPos-1)
    ArrayTemp := StrSplit(FrontString, A_Space)
    SearchTermFront := ArrayTemp[ArrayTemp.Length()]
    ArrayTemp := StrSplit(ForwardLineCaptured, A_Space)
    SearchTermEnd := ArrayTemp[1]
    SearchTerm := SearchTermFront . SearchTermEnd
    SearchTerm := Trim(SearchTerm, ",.!?:;“”'""/()[]{}<>")

    Return [SearchTerm, ExtractError]
}

SendToSelectedDict(SearchTerm) {
    Switch DictSelected {
        Case "GoldenDict":
            SendToGoldenDict(SearchTerm)
        Case "MDict":
            SendToMDict(SearchTerm)
        Case "Eudic":
            SendToEudic(SearchTerm)
    }
    Return
}

; Send the captured text to GoldenDict.
SendToGoldenDict(SearchTerm) {
    SearchTermCli := """" . StrReplace(SearchTerm, """", """""") . """"
    Run, %GoldenDictFileName% %SearchTermCli%
    Return
}

; Send the captured text to MDict.
SendToMDict(SearchTerm) {
    Clipboard := SearchTerm
    Run, %MdictFileName%
    WinWait, ahk_pid MDict.exe, , 0.2
    If WinActive("ahk_exe MDict.exe") {
        Send, ^v
        Sleep, 50
        Send, {Enter}
    }
    Return
}

; Send the captured text to Eudic.
SendToEudic(SearchTerm) {
    Clipboard := SearchTerm
    Run, %EudicFileName%
    WinWait, ahk_pid eudic.exe, , 0.2
    If WinActive("ahk_exe eudic.exe") {
        Send, ^v
        Sleep, 50
        Send, {Enter}
    }
    Return
}

ResetCaptureMode() {
    CaptureMode := "NoCapture"
    CaptureCount := 0
    SetTimer, CaptureTimeout, Off
    Return
}

CaptureTimeout() {
    EndTime := A_TickCount
    ElapsedTime := EndTime - StartTime
    If (ElapsedTime > Timeout) {
        ResetCaptureMode()
        ToolTip, Timeout has expired. Aborting capture.
        SetTimer, TurnOffToolTip, -1000
    }
    Return
}

TurnOffToolTip() {
    ToolTip
    Return
}
;=======================================================================================
; Hotkeys

^RButton::  ; Capture a single word by pressing ctrl + right click.
SingleWordCapture() {
    If !WinExist("ahk_exe Capture2Text.exe") {
        MsgBox, 48, Warning, Capture2Text is not running! Aborting single word capture.
        Return
    }
    StartTime := A_TickCount
    CaptureMode := "SingleWordCapture"
    CaptureCount := 0
    StartLineCapture()
    SetTimer, CaptureTimeout, 1000
    Return
}

^`::  ; Start box capture by pressing ctrl + `
BoxCapture() {
    If !WinExist("ahk_exe Capture2Text.exe") {
        MsgBox, 48, Warning, Capture2Text is not running! Aborting box capture...
        Return
    }
    StartTime := A_TickCount
    CaptureMode := "BoxCapture"
    ToolTip, Hold down left mouse button to start box capture.
    SetTimer, TurnOffToolTip, -1000
    SetTimer, CaptureTimeout, 1000
    Return
}

; Creates context-sensitive hotkeys.
#If (CaptureMode == "BoxCapture")

LButton::
LeftButtonDown() {
    TurnOffToolTip()
    StartBoxCapture()
    Return
}

LButton Up::
LeftButtonUp() {
    Send, {LButton Down}
    Return
}

Esc::
ForceAbortBoxCapture() {
    ToolTip, Aborting box capture.
    SetTimer, TurnOffToolTip, -1000
    ResetCaptureMode()
    Return
}

#If

;=======================================================================================
; Call Capture2Text by sending hotkeys. Hotkeys are defined in Capture2Text.

StartLineCapture() {
    Send, ^+#e  ; crtl + shift + win + e
    Return
}

StartForwardLineCapture() {
    Send, ^+#w  ; crtl + shift + win + w
    Return
}

StartBoxCapture() {
    Send, ^+#q  ; crtl + shift + win + q
    Return
}
;=======================================================================================
