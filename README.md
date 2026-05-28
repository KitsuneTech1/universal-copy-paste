# Universal Copy/Paste

Windows tray utility for stubborn apps and Windows 11 missed-copy behavior.

## What It Does

- `Ctrl+C` uses normal Windows/app copy first.
- If the clipboard does not change, it retries real `Ctrl+C` up to five times.
- If that still fails, it falls back to `Ctrl+Insert`, `WM_COPY`, and UI Automation selected-text copy.
- `Ctrl+V` types the current text clipboard as keystrokes for fields that block normal paste.
- `Ctrl+Shift+V` is left alone for native paste.

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

- `Ctrl+C` = copy with retry/fallback
- `Ctrl+V` = universal plain-text paste
- `Ctrl+Shift+V` = native paste
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
