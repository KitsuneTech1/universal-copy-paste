# SPEC

## Inventory

- Repo kind: quickwin. Existing Windows PowerShell utility.
- Main script: `UniversalCopyPaste.ps1`.
- Launchers: `Start-UniversalCopyPaste.cmd` and `Start-UniversalCopyPaste-Admin.cmd`.
- Startup installer: `Install-UniversalCopyPaste-Startup.ps1` with `Install-UniversalCopyPaste-Startup.cmd`.
- Docs: `README.md` is present and explains hotkeys, install, uninstall, limits, and manual PowerShell usage.
- License: `LICENSE` is present and contains standard MIT text with `Copyright (c) 2026 Kitsune Technologies LLC`.
- Authors: `AUTHORS.md` is present.
- Build system: none. The script compiles inline C# with `Add-Type`.
- Runtime: Windows PowerShell 5.1 or newer on Windows 10 or 11.
- Tests: Pester smoke tests in `tests/`. Compile smoke check is `-CompileOnly`.
- Dependencies: no package manager dependencies.
- CI: GitHub Actions runs the Pester tests on Windows and Ubuntu.

## Smallest honest release

Feature list:

1. Run as a tray utility on Windows with one active instance.
2. Keep native `Ctrl+C` and `Ctrl+V` unchanged by default.
3. Copy selected text with `Ctrl+Alt+C`, sending a copy command to the focused control, then falling back to UI Automation selection text.
4. Paste clipboard text with `Ctrl+Alt+V` by typing Unicode keystrokes as plain text.
5. Toggle the utility with `Ctrl+Alt+Shift+V` and exit with `Ctrl+Alt+Shift+Esc`.

Language and runtime:

- PowerShell 5.1 plus inline C# compiled by `Add-Type`.
- Windows only.

Install command:

```powershell
git clone https://github.com/KitsuneTech1/universal-copy-paste.git
cd universal-copy-paste
```

One command that demonstrates it:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File .\UniversalCopyPaste.ps1 -CompileOnly
```

Runtime demo for users:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File .\UniversalCopyPaste.ps1
```

Then select text in another app, press `Ctrl+Alt+C`, focus a text field, and press `Ctrl+Alt+V`.

Testing plan:

- Add Pester smoke tests for repository shape, required files, MIT license text, launcher targets, and script compile mode.
- Keep the manual runtime check for tray behavior and hotkeys on Windows.
- Use the existing compile command as the automated smoke path until deeper UI automation is justified.

## Release blockers

- `.gitignore` excludes `.env`, `node_modules`, `.venv`, `target`, build artifacts, and `.oss31/`.
- Pester smoke tests pass locally with Pester 3.4.0 and run in CI with Pester 4.10.1.
- Hotkey behavior is verified manually on a Windows desktop. It cannot be exercised from a non-interactive session.
- No tracked secrets, private IPs, Windows user paths, or hardcoded private hostnames were found in release files.
- No dead dependencies were found.
- Compile smoke check passed with `-CompileOnly`.
