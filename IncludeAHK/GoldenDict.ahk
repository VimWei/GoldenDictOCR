; GoldenDict ------------------------------------------------------------o {{{1

; OCR 查词 --------------------------------------------------------------o {{{2
; 使用方法1 - 框选取词：Ctrl + `
; 使用方法2 - 点选取词：Ctrl + 右键

^!o::
	GV_ToggleOCRTakeWord := !GV_ToggleOCRTakeWord
	if (GV_ToggleOCRTakeWord == 1) {
        Run %A_ScriptDir%\IncludeAHK\GdOcrTool.ahk
        if (GV_ToggleMouseTakeWord == 1) {
            fun_SwitchTips("启用OCR取词，并关闭鼠标取词", "Center", "Center", 1000)
            GV_ToggleMouseTakeWord := 0
        }
		else {
			fun_SwitchTips("启用OCR取词", "Center", "Center", 800)
		}
    }
	else {
        fun_SwitchTips("关闭OCR取词", "Center", "Center", 800)
        closeScript("GdOcrTool.ahk")
        ; a := closeScript("GdOcrTool.ahk")
        ; msgbox, %a%
        closeApps("Capture2Text.exe")
        ; b := closeApps("Capture2Text.exe")
        ; msgbox, %b%
    }
return

; 鼠标选择取词 ----------------------------------------------------------o {{{2
; 使用方法：选中文字，即可调用goldendict查词
; 请在GoldenDict中设置：
; [X] F4/热键/剪贴板翻译热键 Ctrl+C+C，必须
; [X] F4/屏幕取词/启用屏幕取词功能，使用体验更佳的Pop小窗口，建议使用，可选
; [ ] F4/屏幕取词/启动程序时同时启动屏幕取词，建议取消

^!i::
	GV_ToggleMouseTakeWord := !GV_ToggleMouseTakeWord
	if (GV_ToggleMouseTakeWord == 1) {
        if (GV_ToggleOCRTakeWord == 1) {
            fun_SwitchTips("启用鼠标取词，并关闭OCR取词", "Center", "Center", 1000)
            GV_ToggleOCRTakeWord := 0
            closeScript("GdOcrTool.ahk")
            closeApps("Capture2Text.exe")
        }
		else {
			fun_SwitchTips("启用鼠标取词", "Center", "Center", 800)
		}
    }
	else {
        fun_SwitchTips("关闭鼠标取词", "Center", "Center", 800)
    }
return

#If GV_ToggleMouseTakeWord == 1
    ~LButton::
        ; 设置取词目标软件黑名单
        ; SetTitleMatchMode, 2
        ; MouseGetPos, ,,win
        ; if ( win = WinActive("GoldenDict")
        ;     or win = WinActive("Total Commander") ){
        ;     return
        ; }

        SetKeyDelay -1, 10
        CoordMode, Mouse, Screen
        MouseGetPos, x1, y1
        KeyWait, LButton
        MouseGetPos, x2, y2
        ; 鼠标选择取词，设置范围防误触
        if (x1-x2>15 or x2-x1>15) {
            oldClipboard := Clipboard
            gosub, GoldenDictCopy
        }
        ; 双击鼠标左键取词
        else if (A_priorHotKey = "~LButton" and A_TimeSincePriorHotkey < 450){
            oldClipboard := Clipboard
            gosub, GoldenDictCopy
        }
    return
#If

GoldenDictCopy:
    Send ^c
    Sleep 200
    if (oldClipboard == Clipboard) {
        return
    }

    ; 过滤剪贴板里包含（中文）/数字/特殊字符的情形
    ; https://zh.wikipedia.org/wiki/ASCII
    len := strlen(clipboard)
    index := 1
    loop {
        code := asc( substr(clipboard, index, 1) )
        if( code < 20
            or code >= 33 and code <= 38
            or code >= 40 and code <= 44
            or code >= 46 and code <= 64
            or code >= 91 and code <= 96
            ; or code > 127  ; 中文
            or code >= 123 and code <= 126 ) {
            Clipboard := oldClipboard
            return
        }
        ++index
        if(index > len)
            break
    }

    ; 剪贴板里的字词长度不能小于3
    ; if(len <3){
    ;     Clipboard := oldClipboard
    ;     return
    ; }

    ; 发送全局的 ctrl+C+C，触发GoldenDict查询
    Send ^{c 2}
    Sleep 200
    ; 恢复原始剪贴板内容，因此本查词不会污染剪贴板
    Clipboard := oldClipboard
return

;------------------------------------------------------------------------o

; /* Vim: set foldmethod=marker: */
