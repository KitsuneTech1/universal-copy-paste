@echo off
set "SCRIPT=%~dp0UniversalCopyPaste.ps1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell.exe -WindowStyle Hidden -ArgumentList '-NoProfile -ExecutionPolicy Bypass -STA -File ""%SCRIPT%""'"
