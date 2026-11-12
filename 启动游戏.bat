@echo off
chcp 65001 >nul
setlocal

set "PROJ=%~dp0"
set "PROJ=%PROJ:~0,-1%"

set "GODOT="

rem 1) 优先使用项目自带的 tools 目录
if exist "%PROJ%\tools\Godot_v4.7.2-stable_win64.exe" set "GODOT=%PROJ%\tools\Godot_v4.7.2-stable_win64.exe"

rem 2) 常见安装位置
if not defined GODOT if exist "D:\table tennis game test\godot\tools\Godot_v4.7.2-stable_win64.exe" set "GODOT=D:\table tennis game test\godot\tools\Godot_v4.7.2-stable_win64.exe"
if not defined GODOT if exist "C:\Program Files\Godot\Godot_v4.7.2-stable_win64.exe" set "GODOT=C:\Program Files\Godot\Godot_v4.7.2-stable_win64.exe"
if not defined GODOT if exist "C:\Program Files (x86)\Godot\Godot_v4.7.2-stable_win64.exe" set "GODOT=C:\Program Files (x86)\Godot\Godot_v4.7.2-stable_win64.exe"

rem 3) PATH 里的 godot
if not defined GODOT for %%G in (godot.exe godot4.exe) do (
    if not defined GODOT if exist "%%~$PATH:G" set "GODOT=%%~$PATH:G"
)

if not defined GODOT (
    echo.
    echo  没有找到 Godot 4.7。
    echo.
    echo  请安装 Godot 4.7 后重试，或直接用编辑器打开：
    echo    %PROJ%\project.godot
    echo.
    pause
    exit /b 1
)

echo 使用引擎：%GODOT%
start "" "%GODOT%" --path "%PROJ%"
