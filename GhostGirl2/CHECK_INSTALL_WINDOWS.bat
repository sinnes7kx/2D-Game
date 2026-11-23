@echo off
cd /d "%~dp0"
if not exist "project.godot" goto missing
if not exist "scenes\main.tscn" goto missing
if not exist "scenes\player.tscn" goto missing
if not exist "resources\ghost_girl_frames.tres" goto missing
if not exist "assets\ghost\idle_front_00.png" goto missing
if not exist "assets\ghost\combat_v14\attack_unarmed_light_front_00.png" goto missing
if not exist "assets\ghost\combat_v14\attack_sword_light_front_00.png" goto missing
if not exist "128 frames.png" goto missing
if not exist "scripts\player.gd" goto missing
if not exist "assets\world\moonwake_crypt.png" goto missing
echo Critical Godot files are present.
where py >nul 2>nul
if %ERRORLEVEL% EQU 0 (py -3 "tools\verify_install.py") else (echo Optional: install Python to run tools\verify_install.py for a full reference check.)
pause
exit /b 0
:missing
echo ERROR: Some required Ghost Girl project files are absent.
echo Unzip the full project into a NEW empty folder or merge all parts.
pause
exit /b 1
