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

## Run it yourself

### What you need

- **Windows 10 or 11.** That's it. PowerShell comes built in, there is nothing to install.
- To check your Windows version: press `Win + R`, type `winver`, press Enter. It'll show you the version in a popup.

### Step by step

**Getting the files**

If you have git, clone it:

```powershell
git clone https://github.com/KitsuneTech1/universal-copy-paste.git
```

If you don't have git, that's fine, no need to install it. On this page on GitHub, click the green **Code** button, then **Download ZIP**. Once it downloads, right-click the zip file and choose **Extract All**, then open the extracted folder.

**Starting it**

1. Open the folder in File Explorer (double-click it, or right-click the zip and Extract All first if you downloaded a zip).
2. Double-click **`Start-UniversalCopyPaste.cmd`**. A window may flash briefly and disappear. That's normal, it's meant to run quietly in the background.
3. Look at the bottom-right corner of your screen, in the system tray (the small icons near the clock). You may need to click the little up-arrow to show hidden icons. You should see a new tray icon for this tool.
4. If you need it to work inside programs running "as administrator," double-click **`Start-UniversalCopyPaste-Admin.cmd`** instead. Windows will show a User Account Control popup asking for permission, click **Yes**.
5. If you want it to start automatically every time you log into Windows, double-click **`Install-UniversalCopyPaste-Startup.cmd`**. A black window will show a short message and then say "Press any key to continue," press any key and it closes. This just places a shortcut in your Windows Startup folder, nothing else changes.

**It worked if:** you see the tray icon near the clock, and pressing `Ctrl+Alt+C` then `Ctrl+Alt+V` in a text field copies and retypes your selected text.

**Troubleshooting**

- *Nothing happens when I double-click the .cmd file:* Windows sometimes blocks downloaded scripts. Right-click the `.cmd` file, choose **Properties**, and if you see an "Unblock" checkbox near the bottom, check it and click OK, then try again.
- *No tray icon appears:* click the small up-arrow (^) near the clock to see hidden tray icons, it may just be tucked away there.
- *It says the tool is "already running":* it only allows one copy at a time. Look for the existing tray icon, or restart your PC and try again.
- *Pasting doesn't work in a specific app:* some apps (password fields, some remote-desktop sessions) block this on purpose. See the Limits section below.

### Advanced: running it manually from PowerShell

If you want to pass options instead of using the `.cmd` launchers, open PowerShell (right-click the Start button, choose **Windows Terminal** or **PowerShell**), `cd` into the folder you extracted, and run:

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
