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
- Tests: no Pester test suite yet. Current smoke check is `-CompileOnly`.
- Dependencies: no package manager dependencies.
- Current git state before this spec: `.gitignore` already has an uncommitted change adding `.oss31/`.

## Smallest honest release

Feature list:

1. Run as a tray utility on Windows with one active instance.
2. Keep native `Ctrl+C` and `Ctrl+V` unchanged by default.
3. Copy selected text with `Ctrl+Alt+C`, using native copy first, then focused control copy, then UI Automation selection text.
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

- `.gitignore` does not yet exclude `.env`, `node_modules`, `.venv`, `target`, or general build artifacts. It only excludes `.oss31/` in the current uncommitted edit.
- Pester smoke tests are missing.
- README still depends on manual verification for hotkey behavior.
- No tracked secrets, private IPs, Windows user paths, or hardcoded private hostnames were found in release files.
- No dead dependencies were found.
- Compile smoke check passed with `-CompileOnly`.
