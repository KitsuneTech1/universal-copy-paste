# Universal Copy/Paste

Backup copy and universal plain-text paste for Windows apps that block the normal clipboard shortcuts.

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)](https://learn.microsoft.com/powershell/)
[![Platform: Windows](https://img.shields.io/badge/platform-Windows-0078D6?logo=windows&logoColor=white)](https://www.microsoft.com)

Some apps eat `Ctrl+C`, some block `Ctrl+V`, and Windows 11 has its own habit of dropping copies mid-selection. This runs quietly in the tray and gives you a fallback for both, without touching your normal copy and paste shortcuts unless you ask it to.

## Demo

It is a background utility, so the demo is the hotkey table:

| Hotkey | Action |
|---|---|
| `Ctrl+C` | Native copy (untouched by default) |
| `Ctrl+V` | Native paste (untouched by default) |
| `Ctrl+Alt+C` | Backup copy: grabs the selection even if native copy failed |
| `Ctrl+Alt+V` | Universal paste: types the clipboard text as keystrokes |
| `Ctrl+Alt+Shift+V` | Toggle the utility on/off |
| `Ctrl+Alt+Shift+Esc` | Exit |

A tray icon also gives you an enable/disable checkbox and an exit option.

## Features

- Backup copy on `Ctrl+Alt+C`: if the native copy did not put anything new on the clipboard, it falls back to sending a `WM_COPY` message to the focused control, then to reading the selected text through UI Automation.
- Universal paste on `Ctrl+Alt+V`: reads the clipboard text and types it out as Unicode keystrokes, so it works in fields and remote sessions that block a real paste.
- Native `Ctrl+C` / `Ctrl+V` are left alone by default. Optional flags let you fully take them over if you want backup copy and universal paste on the normal shortcuts.
- Tray icon with an enable/disable toggle, no window, no taskbar clutter.
- Single instance only. Launching it twice just logs that it is already running.
- Works entirely locally. No network calls, no telemetry.

## Install

### One-click (recommended)

1. Download or clone this repo.
2. Run `Start-UniversalCopyPaste.cmd` to start it in the background.
3. If you need it to paste into elevated/admin windows, run `Start-UniversalCopyPaste-Admin.cmd` instead (it will prompt for UAC).
4. To have it start automatically at login, run `Install-UniversalCopyPaste-Startup.cmd`. This drops a shortcut in your Startup folder pointing at `Start-UniversalCopyPaste.cmd`.

### Manual

Run the script directly with PowerShell in STA mode:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File .\UniversalCopyPaste.ps1
```

Optional switches:

- `-StartDisabled` - start with the utility toggled off.
- `-TakeOverCtrlC` - make plain `Ctrl+C` also run backup copy.
- `-TakeOverCtrlV` - make plain `Ctrl+V` also run universal paste.
- `-CompileOnly` - just verify the script compiles, then exit. Useful for a quick sanity check after editing:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File .\UniversalCopyPaste.ps1 -CompileOnly
```

## How It Works

The script compiles a small C# helper inline and installs a low-level keyboard hook (`WH_KEYBOARD_LL`) to watch for the hotkeys above. Everything else runs off that hook:

- Backup copy waits for the copy keys to release, checks the clipboard sequence number for a change, and if nothing changed it tries a direct `WM_COPY` message to the focused control, then falls back to reading the selection through the UI Automation `TextPattern`.
- Universal paste reads Unicode text off the clipboard and replays it with `SendInput` using `KEYEVENTF_UNICODE`, character by character, so the target app sees real keystrokes instead of a paste event.
- A `Mutex` keeps only one copy of the tool running at a time.

## Uninstall

1. Exit the tray icon (or press `Ctrl+Alt+Shift+Esc`).
2. If you installed the startup shortcut, delete `Universal Copy Paste.lnk` from your Startup folder (`shell:startup` in the Run dialog).
3. Delete the repo folder.

## Limits

The backup copy path can only copy text that Windows, the target app, or the UI Automation layer expose. Protected password fields and apps that deliberately hide their text may still refuse to be copied.

Paste is plain text only. Images and rich formatting fall back to normal paste when the clipboard has no text. Be careful pasting multi-line commands into terminals, since this types keystrokes instead of using terminal paste guardrails.

Plain `Ctrl+C` / `Ctrl+V` takeover only happens when you launch the script with `-TakeOverCtrlC` or `-TakeOverCtrlV`. The default launcher does not use either, since globally intercepting the basic clipboard shortcuts can break normal behavior in some apps.

## License

MIT, see [LICENSE](LICENSE).

---

Built by [Kitsune Technologies](https://kitsunetechnologies.org). See more of our work at [kitsunetechnologies.org/work](https://kitsunetechnologies.org/work). Issues and PRs welcome.
