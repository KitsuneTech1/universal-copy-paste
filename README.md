Universal Copy/Paste is a Windows PowerShell tray utility that copies selected text with a fallback hotkey and pastes clipboard text as plain text in apps that block normal paste.

## What it does

- Runs as a tray utility on Windows with one active instance.
- Keeps native `Ctrl+C` and `Ctrl+V` unchanged by default.
- Copies selected text with `Ctrl+Alt+C`, using native copy first, then focused control copy, then UI Automation selection text.
- Pastes clipboard text with `Ctrl+Alt+V` by typing Unicode keystrokes as plain text.
- Toggles the utility with `Ctrl+Alt+Shift+V`.
- Exits with `Ctrl+Alt+Shift+Esc`.

## What you need

- Windows 10 or Windows 11.
- Windows PowerShell 5.1. It is included with Windows 10 and 11. Download or update it from [Windows Management Framework 5.1](https://learn.microsoft.com/powershell/scripting/windows-powershell/wmf/setup/install-configure).
- Git, if you want to install with the command below. Download it from [git-scm.com](https://git-scm.com/download/win).

## Install

1. Clone the repository.

```powershell
git clone https://github.com/KitsuneTech1/universal-copy-paste.git
```

Expected output starts like this:

```text
Cloning into 'universal-copy-paste'...
```

2. Enter the folder.

```powershell
cd universal-copy-paste
```

Expected output: none. Your prompt should now end with `universal-copy-paste`.

3. Check that the script compiles.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File .\UniversalCopyPaste.ps1 -CompileOnly
```

Expected output:

```text
UniversalCopyPaste compiled successfully.
```

## Use it

Start the tray utility:

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

You can also double-click `Start-UniversalCopyPaste.cmd` from File Explorer. Use `Start-UniversalCopyPaste-Admin.cmd` if the target app is running as administrator.

Screenshot: docs/demo.png (coming)

## It worked if ...

- You see a tray icon near the Windows clock.
- `Ctrl+Alt+C` copies selected text from a normal text field.
- `Ctrl+Alt+V` types that text into another field.
- `Ctrl+C` and `Ctrl+V` still behave normally.

## Troubleshooting

- `UniversalCopyPaste.ps1 cannot be loaded because running scripts is disabled on this system.` Run the command from this README. It uses `-ExecutionPolicy Bypass` for this process only.
- `UniversalCopyPaste only supports Windows.` Run it on Windows 10 or 11. This tool does not run on macOS or Linux.
- `Universal Copy/Paste is already running.` Only one copy can run at a time. Use the tray icon that is already near the clock, or press `Ctrl+Alt+Shift+Esc` to exit it.
- `Could not install the keyboard hook.` Start PowerShell normally and try again. If the target app runs as administrator, use `Start-UniversalCopyPaste-Admin.cmd`.

## License

MIT. See [LICENSE](LICENSE).
