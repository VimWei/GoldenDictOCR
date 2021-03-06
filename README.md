# GoldenDictOCR
by Vim 2021-11-14 星期日 19:09:30

![demo](demo.gif)

## 特点

* 既可以使用OCR进行查词（特别是图片等难以选中文字的情形）
* 也可以鼠标选择查询（适合于文本可选择，特别是英文词组、难以自动分词的中文等情形）
* 自动启用、关闭相关软件（Capture2Text.exe，GdOcrTool.ahk等）
* 不同查词模式智能切换，且屏幕有提醒当前模式

## 安装和配置

1. 安装 GoldenDict、Capture2Text、AutoHotkey到任意位置
2. 解压GoldenDictOCR到任意位置
3. 在GdOcrTool.ahk中配置好GoldenDict和Capture2Text的安装地址
4. 配置Capture2Text：复制Capture2Text.ini到"%appdata%\Capture2Text"

## 使用方法

1. 双击打开GoldenDictOCR.ahk，随时准备响应（可以将其加入开机启动）
2. Ctrl + Alt + O：开启或关闭 OCR 取词
    * 开启之后，点选取词：ctrl + 右键
    * 开启之后，框选取词：ctrl + `
3. Ctrl + Alt + I：开启或关闭鼠标选择取词
    * 开启之后，鼠标拖拉选择或双击自动选择文字取词

## 查词大比拼

大家试一试如何才能不更改配置即实现多种情形的查询：
* https://www.apple.com/shop/gifts
这个案例页面，文字有大有小、有图片有文字，通常工具查询有难度

但在这里so easy!

## 论坛讨论

* https://forum.freemdict.com/t/topic/9311

## Acknowledge

* Thanks Johnny_Van for your GdOcrTool.ahk！ https://forum.freemdict.com/t/topic/7166
* Thanks Capture2Text  http://capture2text.sourceforge.net/

## LICENSE

* [GPLv3](https://www.gnu.org/licenses/gpl-3.0.en.html)
