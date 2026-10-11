<p align="center"><a href="https://kitsunetechnologies.org/work"><img src="https://raw.githubusercontent.com/KitsuneTech1/.github/main/assets/kitsune-banner.svg" alt="Built by Kitsune Technologies" width="760"></a></p>

# Universal Copy/Paste

Windows hotkeys that copy anything and paste it as plain text, in every app.

Universal Copy/Paste is a small PowerShell tray utility. `Ctrl+Alt+C` copies the selected text even when an app blocks normal copy. `Ctrl+Alt+V` types the clipboard as plain text keystrokes, so it works in fields and remote sessions that block normal paste. Your normal `Ctrl+C` and `Ctrl+V` stay untouched.

## What it does

- Runs as a tray utility on Windows with one active instance.
- Keeps native `Ctrl+C` and `Ctrl+V` unchanged by default.
- Copies selected text with `Ctrl+Alt+C`. It sends a copy command to the focused control, then falls back to reading the selection through UI Automation.
- Pastes clipboard text with `Ctrl+Alt+V` by typing Unicode keystrokes as plain text. Formatting is dropped.
- Toggles the utility with `Ctrl+Alt+Shift+V`.
- Exits with `Ctrl+Alt+Shift+Esc`.
- Runs entirely on your PC. No network calls, no telemetry.

## What you need

- Windows 10 or Windows 11.
- Windows PowerShell 5.1. It is included with Windows 10 and 11.
- Git is optional. You can download a ZIP instead.

## Install

1. Get the files.

With Git:

```powershell
git clone https://github.com/KitsuneTech1/universal-copy-paste.git
```

Expected output starts like this:

```text
Cloning into 'universal-copy-paste'...
```

Without Git: on the GitHub page, click the green **Code** button, then **Download ZIP**. Right-click the ZIP file and choose **Extract All**. The extracted folder is named `universal-copy-paste-main`. Use that name in the next step.

2. Open PowerShell and enter the folder.

```powershell
cd universal-copy-paste
```

Expected output: none. The prompt now shows the folder path.

3. Check that the script compiles.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File .\UniversalCopyPaste.ps1 -CompileOnly
```

Expected output:

```text
UniversalCopyPaste compiled successfully.
```

## Use it

Double-click `Start-UniversalCopyPaste.cmd` in File Explorer. A console window may flash and close. That is normal. The utility runs hidden and prints nothing. Look for its icon in the tray near the clock.

Use `Start-UniversalCopyPaste-Admin.cmd` instead if the app you want to paste into runs as administrator. Windows shows a User Account Control prompt. Click **Yes**.

To see the startup messages, start it from PowerShell instead:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File .\UniversalCopyPaste.ps1
```

You should see this output:

```text
Universal Copy/Paste is running.
Ctrl+C: native copy
Ctrl+Alt+C: backup copy
Ctrl+V: native paste
Ctrl+Alt+V: universal text paste
Ctrl+Alt+Shift+V: toggle universal copy/paste
Ctrl+Alt+Shift+Esc: exit
```

Then select text in another app, press `Ctrl+Alt+C`, focus a text field, and press `Ctrl+Alt+V`. It types the copied text as plain text.

Quick self-test:

1. Open Notepad and type a line of text.
2. Select the line and press `Ctrl+Alt+C`.
3. Press `End`, then `Enter`, then `Ctrl+Alt+V`.
4. The same line appears again, typed as keystrokes.

## It worked if ...

- You see a tray icon near the Windows clock. Click the small up arrow near the clock if it is hidden.
- The self-test above repeats your line in Notepad.
- `Ctrl+C` and `Ctrl+V` still behave normally.

## Run at startup

Double-click `Install-UniversalCopyPaste-Startup.cmd`. It places a shortcut to `Start-UniversalCopyPaste.cmd` in your Startup folder. Nothing else changes.

## Options

Pass these switches when you start the script from PowerShell:

- `-StartDisabled` starts with the hotkeys paused. Toggle them on with `Ctrl+Alt+Shift+V`.
- `-TakeOverCtrlC` makes plain `Ctrl+C` also run the backup copy.
- `-TakeOverCtrlV` makes plain `Ctrl+V` also run the plain text paste.
- `-CompileOnly` checks that the script compiles, then exits.

## Troubleshooting

- `UniversalCopyPaste.ps1 cannot be loaded because running scripts is disabled on this system.` Run the command from this README. It uses `-ExecutionPolicy Bypass` for this process only.
- Nothing happens when you double-click a `.cmd` file. Windows sometimes blocks downloaded scripts. Right-click the file, choose **Properties**, check **Unblock** if it is shown, click **OK**, and try again. If there is no **Unblock** box, start it from PowerShell with the command above.
- `UniversalCopyPaste only supports Windows.` Run it on Windows 10 or 11. This tool does not run on macOS or Linux.
- `Universal Copy/Paste is already running.` Only one copy can run at a time. Use the tray icon that is already near the clock, or press `Ctrl+Alt+Shift+Esc` to exit it.
- `Could not install the keyboard hook.` Start PowerShell normally and try again. If the target app runs as administrator, use `Start-UniversalCopyPaste-Admin.cmd`.
- Paste does nothing in one app. Some apps block synthetic keystrokes on purpose, such as password fields and some remote desktop clients.

## Limits

- Backup copy can only read text that the app or UI Automation exposes. Password fields and apps that hide their text stay protected.
- Paste is plain text only. If the clipboard has no text, `Ctrl+Alt+V` does nothing.
- Pasting multi-line text into a terminal types each line and presses Enter. Check the clipboard first.

## Uninstall

1. Exit the tray icon, or press `Ctrl+Alt+Shift+Esc`.
2. If you installed the startup shortcut, delete `Universal Copy Paste.lnk` from your Startup folder. Press `Win+R`, type `shell:startup`, press Enter.
3. Delete the folder.

## License

MIT. See [LICENSE](LICENSE).
