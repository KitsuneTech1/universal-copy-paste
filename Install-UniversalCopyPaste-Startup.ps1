$ErrorActionPreference = "Stop"

$startup = [Environment]::GetFolderPath("Startup")
$target = Join-Path $PSScriptRoot "Start-UniversalCopyPaste.cmd"
$shortcutPath = Join-Path $startup "Universal Copy Paste.lnk"

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $target
$shortcut.WorkingDirectory = $PSScriptRoot
$shortcut.IconLocation = "$env:SystemRoot\System32\shell32.dll,245"
$shortcut.Description = "Start Universal Copy/Paste"
$shortcut.Save()

Write-Host "Installed startup shortcut:"
Write-Host $shortcutPath

