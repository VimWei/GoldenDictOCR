; 提示信息展示板
; 案例1：fun_SwitchTips("单键模式启用", 0.7, 0.7, 800)
; 案例2：fun_SwitchTips("启用鼠标取词", "Center", "Center", 800)
fun_SwitchTips(SW_Tips, SW_PositionX, SW_PositionY, SW_ShowTime) {
    WinGet, CurWin_Active_id, ID, A
    if (SW_PositionX != "Center") {
        ; 适用于参数为屏幕宽度的比例值，采用0.7等小数表示
        WindowTipsx := SW_PositionX*A_ScreenWidth
    } else {
        ; 适用于参数为屏幕居中，采用"Center"表示，注意需带引号
        WindowTipsx := SW_PositionX
    }
    if (SW_PositionY != "Center") {
        WindowTipsy := SW_PositionY*A_ScreenHeight
    } else {
        WindowTipsy := SW_PositionY
    }
    Gui, Color, 37474F
    Gui -Caption
    Gui, Font, s32, Microsoft YaHei
    Gui, +AlwaysOnTop +Disabled -SysMenu +Owner
    Gui, Add, Text, cffffff, %SW_Tips%
    Gui, Show, x%WindowTipsx% y%WindowTipsy%, NoActivate
    sleep, %SW_ShowTime%
    Gui, Destroy
    WinActivate, ahk_id %CurWin_Active_id%
}

; 关闭其他AHK
closeScript(Name) {
    DetectHiddenWindows On
    SetTitleMatchMode RegEx
    IfWinExist, i)%Name%.* ahk_class AutoHotkey
        {
        WinClose
        WinWaitClose, i)%Name%.* ahk_class AutoHotkey, , 2
        If ErrorLevel
            return "Unable to close " . Name
        else
            return "Closed " . Name
        }
    else
        return Name . " not found"
}

; 关闭其他Apps
closeApps(Name) {
    DetectHiddenWindows On
    SetTitleMatchMode RegEx
    process, exist, %Name%
    pid = %ErrorLevel%
    Process, Close, %pid%
}
