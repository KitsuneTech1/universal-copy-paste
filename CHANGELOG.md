# Changelog

## v0.1.0 - 2026-10-11

First public release. Universal Copy/Paste runs as a Windows tray utility. It copies selected text with Ctrl+Alt+C by sending a copy command to the focused control, then falling back to UI Automation, and pastes clipboard text as plain keystrokes with Ctrl+Alt+V so it works in apps that block normal paste. Native Ctrl+C and Ctrl+V stay unchanged by default. Toggle with Ctrl+Alt+Shift+V and exit with Ctrl+Alt+Shift+Esc. Ships with launchers, a startup installer, Pester smoke tests, and an MIT license.
