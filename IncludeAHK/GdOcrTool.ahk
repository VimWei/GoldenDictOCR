;=======================================================================================
; GdOcrTool.ahk is an AutoHotkey (v1.1) script to enhance the GoldenDict with OCR
; functionality using Capture2Text.
; Written by Johnny Van, 2021/11/13
;=======================================================================================
; Auto-execution section.

#NoEnv
#SingleInstance, force
SendMode Input
SetWorkingDir %A_ScriptDir%
SetBatchLines -1
CoordMode, ToolTip, Screen

Global GoldenDictFileName := "d:\PortableApps\PortableApps\GoldenDict\GoldenDict.exe"
Global Capture2TextFileName := "c:\Apps\Capture2Text\Capture2Text.exe"
Global CaptureMode := "NoCapture"  ; CaptureMode: "NoCapture", "SingleWordCapture", "BoxCapture"
Global CaptureCount := 0
Global LineCaptured := ""
Global ForwardLineCaptured := ""
Global TimeOut := 6000

Main()

;=======================================================================================
;

Main() {
    Menu, Tray, Icon, shell32.dll, 172
    OnClipboardChange("ClipboardChange")
;    Run % GoldenDictFileName
    Run % Capture2TextFileName
;    Run % A_ScriptDir . "\Capture2Text.exe"
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
                SendToGD(SearchTerm)
            }
        Default:
            ResetCaptureMode()
    }
    Return
}

BoxCaptureHandler() {
    ResetCaptureMode()
    SendToGD(Clipboard)
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

; Send the captured text to GoldenDict.
SendToGD(SearchTerm) {
    SearchTermCli := """" . StrReplace(SearchTerm, """", """""") . """"
    Run, %GoldenDictFileName% %SearchTermCli%
    Return
}

ResetCaptureMode() {
    CaptureMode := "NoCapture"
    CaptureCount := 0
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
    CaptureMode := "SingleWordCapture"
    CaptureCount := 0
    StartLineCapture()
    Return
}

^`::  ; Start box capture by pressing ctrl + `
BoxCapture() {
    CaptureMode := "BoxCapture"
    ToolTip, Hold down left mouse button to start box capture.
    SetTimer, TurnOffToolTip, -1000
    Return
}

LButton::
LeftButtonDown() {
    If (CaptureMode != "BoxCapture") {
        Send, {LButton Down}
    } Else {
        TurnOffToolTip()
        StartBoxCapture()
    }
    Return
}

LButton Up::
LeftButtonUp() {
    If (CaptureMode != "BoxCapture") {
        Send, {LButton Up}
    } Else {
        Send, {LButton Down}
    }
    Return
}

;=======================================================================================
; Hotkeys defined in Capture2Text.

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
