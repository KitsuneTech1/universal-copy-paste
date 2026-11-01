@echo off
pushd "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell.exe -Verb RunAs -WorkingDirectory (Get-Location) -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-STA','-File','.\UniversalCopyPaste.ps1')"
popd

