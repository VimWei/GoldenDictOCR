#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey
#SingleInstance force       ; 一个脚本只能有一个实例，新实例会自动替换旧实例
#Persistent                 ; 让脚本持久运行(除非关闭或ExitApp)
#MaxMem 4	                ; 每个变量可使用的最大内存兆数
#WinActivateForce           ; 阻止在快速连续激活窗口时任务栏按钮的闪烁
#MaxHotkeysPerInterval 100  ; Avoid warning when mouse wheel turned very fast

SendMode Input              ; Recommended for superior speed and reliability
SetKeyDelay, -1			    ; 设置每次Send和ControlSend发送键击后无延时
SetWinDelay, 0              ; 每次执行窗口命令后最小延时
SetControlDelay, 0          ; 每次控件修改命令执行后最小延时

SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory
DetectHiddenWindows, on     ; 可检测到隐藏窗口
SetTitleMatchMode, 2        ; 窗口标题的某个位置包含 WinTitle 即可匹配

Menu, Tray, Icon, IncludeAHK\GO.ico

#Include %A_ScriptDir%\IncludeAHK\PublicIncludes.ahk
#Include %A_ScriptDir%\IncludeAHK\GoldenDict.ahk
