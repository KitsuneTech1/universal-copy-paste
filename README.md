# Universal Copy/Paste

Windows tray utility for stubborn apps and Windows 11 missed-copy behavior.

## What It Does

- `Ctrl+C` is left alone for normal/native copy.
- `Ctrl+Alt+C` runs backup copy through app/API/accessibility methods.
- `Ctrl+V` is left alone for normal/native paste.
- `Ctrl+Alt+V` types the current text clipboard as keystrokes for fields that block normal paste.

## Start

Run:

```text
Start-UniversalCopyPaste.cmd
```

If you need it to paste into elevated/admin windows, run:

```text
Start-UniversalCopyPaste-Admin.cmd
```

## Controls

- `Ctrl+C` = native copy
- `Ctrl+Alt+C` = backup copy
- `Ctrl+V` = native paste
- `Ctrl+Alt+V` = universal plain-text paste
- `Ctrl+Alt+Shift+V` = toggle the utility on/off
- `Ctrl+Alt+Shift+Esc` = exit

There is also a tray icon with an enable toggle and exit option.

## Start With Windows

Run:

```text
Install-UniversalCopyPaste-Startup.cmd
```

## Verify Compile

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File .\UniversalCopyPaste.ps1 -CompileOnly
```

## Limits

The backup copy path can only copy text that Windows, the target app, or the UI Automation layer exposes. Protected password fields and apps that deliberately hide text may still refuse copying.

Paste is plain text. Images and rich formatting use normal paste when the clipboard does not contain text. Be careful pasting multi-line commands into terminals, because this types keystrokes instead of using terminal paste guardrails.

Plain `Ctrl+C` / `Ctrl+V` takeover is available only when explicitly starting
the script with `-TakeOverCtrlC` or `-TakeOverCtrlV`. The default launcher does
not use either because globally intercepting basic clipboard shortcuts can break
normal behavior in some apps.
