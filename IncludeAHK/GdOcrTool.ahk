;=======================================================================================
; GdOcrTool.ahk is an AutoHotkey (v1.1) script to enhance the GoldenDict with OCR
; functionality using Capture2Text.
; Written by Johnny Van, 2021/11/13
; Updated 2021/11/14, add support for MDict, Eudic.
; Updated 2021/11/19, add visual feedback for single word capture.
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
    } Else {
        Run % Capture2TextFileName
    }

    Switch DictSelected {
        Case "GoldenDict":
            If !FileExist(GoldenDictFileName) {
                MsgBox, 48, Warning, GoldenDict.exe not found! Exiting program...
                ExitApp
            } Else If !WinExist("ahk_exe GoldenDict.exe") {
                Run % GoldenDictFileName
            }
        Case "MDict":
            If !FileExist(MDictFileName) {
                MsgBox, 48, Warning, MDict.exe not found! Exiting program...
                ExitApp
            } Else If !WinExist("ahk_exe MDict.exe") {
                Run % MDictFileName
            }
        Case "Eudic":
            If !FileExist(EudicFileName) {
                MsgBox, 48, Warning, eudic.exe not found! Exiting program...
                ExitApp
            } Else If !WinExist("ahk_exe eudic.exe") {
                Run % EudicFileName
            }
    }

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
                ToolTip % SearchTerm
                SetTimer, TurnOffToolTip, -1000
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
    WinWait, ahk_exe MDict.exe, , 0.2
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
    WinWait, ahk_exe eudic.exe, , 0.2
    If WinActive("ahk_exe eudic.exe") {
        Send, ^v
        Sleep, 50
        Send, {Enter}
    }
    Return
}

ResetCaptureMode() {
    CaptureMode := "NoCapture"
	RestoreCursors()
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
        Run % Capture2TextFileName
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
        Run % Capture2TextFileName
        Return
    }
    CaptureMode := "BoxCapture"
	SetSystemCursor("IDC_CROSS")
    ToolTip, Hold down left mouse button to start box capture.
    SetTimer, TurnOffToolTip, -1000
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
    StartTime := A_TickCount  ; Start count down after box is drawn.
    SetTimer, CaptureTimeout, 1000
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

SetSystemCursor( Cursor = "", cx = 0, cy = 0 )
{
	BlankCursor := 0, SystemCursor := 0, FileCursor := 0 ; init

	SystemCursors = 32512IDC_ARROW,32513IDC_IBEAM,32514IDC_WAIT,32515IDC_CROSS
	,32516IDC_UPARROW,32640IDC_SIZE,32641IDC_ICON,32642IDC_SIZENWSE
	,32643IDC_SIZENESW,32644IDC_SIZEWE,32645IDC_SIZENS,32646IDC_SIZEALL
	,32648IDC_NO,32649IDC_HAND,32650IDC_APPSTARTING,32651IDC_HELP

	If Cursor = ; empty, so create blank cursor
	{
		VarSetCapacity( AndMask, 32*4, 0xFF ), VarSetCapacity( XorMask, 32*4, 0 )
		BlankCursor = 1 ; flag for later
	}
	Else If SubStr( Cursor,1,4 ) = "IDC_" ; load system cursor
	{
		Loop, Parse, SystemCursors, `,
		{
			CursorName := SubStr( A_Loopfield, 6, 15 ) ; get the cursor name, no trailing space with substr
			CursorID := SubStr( A_Loopfield, 1, 5 ) ; get the cursor id
			SystemCursor = 1
			If ( CursorName = Cursor )
			{
				CursorHandle := DllCall( "LoadCursor", Uint,0, Int,CursorID )
				Break
			}
		}
		If CursorHandle = ; invalid cursor name given
		{
			Msgbox,, SetCursor, Error: Invalid cursor name
			CursorHandle = Error
		}
	}
	Else If FileExist( Cursor )
	{
		SplitPath, Cursor,,, Ext ; auto-detect type
		If Ext = ico
			uType := 0x1
		Else If Ext in cur,ani
			uType := 0x2
		Else ; invalid file ext
		{
			Msgbox,, SetCursor, Error: Invalid file type
			CursorHandle = Error
		}
		FileCursor = 1
	}
	Else
	{
		Msgbox,, SetCursor, Error: Invalid file path or cursor name
		CursorHandle = Error ; raise for later
	}
	If CursorHandle != Error
	{
		Loop, Parse, SystemCursors, `,
		{
			If BlankCursor = 1
			{
				Type = BlankCursor
				%Type%%A_Index% := DllCall( "CreateCursor"
				, Uint,0, Int,0, Int,0, Int,32, Int,32, Uint,&AndMask, Uint,&XorMask )
				CursorHandle := DllCall( "CopyImage", Uint,%Type%%A_Index%, Uint,0x2, Int,0, Int,0, Int,0 )
				DllCall( "SetSystemCursor", Uint,CursorHandle, Int,SubStr( A_Loopfield, 1, 5 ) )
			}
			Else If SystemCursor = 1
			{
				Type = SystemCursor
				CursorHandle := DllCall( "LoadCursor", Uint,0, Int,CursorID )
				%Type%%A_Index% := DllCall( "CopyImage"
				, Uint,CursorHandle, Uint,0x2, Int,cx, Int,cy, Uint,0 )
				CursorHandle := DllCall( "CopyImage", Uint,%Type%%A_Index%, Uint,0x2, Int,0, Int,0, Int,0 )
				DllCall( "SetSystemCursor", Uint,CursorHandle, Int,SubStr( A_Loopfield, 1, 5 ) )
			}
			Else If FileCursor = 1
			{
				Type = FileCursor
				%Type%%A_Index% := DllCall( "LoadImageA"
				, UInt,0, Str,Cursor, UInt,uType, Int,cx, Int,cy, UInt,0x10 )
				DllCall( "SetSystemCursor", Uint,%Type%%A_Index%, Int,SubStr( A_Loopfield, 1, 5 ) )
			}
		}
	}
      Return
}

RestoreCursors()
{
	SPI_SETCURSORS := 0x57
	DllCall( "SystemParametersInfo", UInt,SPI_SETCURSORS, UInt,0, UInt,0, UInt,0 ) ; Reload the system cursors
    Return
}
