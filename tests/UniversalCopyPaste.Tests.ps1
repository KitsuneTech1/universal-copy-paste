$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$mainScript = Join-Path $repoRoot "UniversalCopyPaste.ps1"
$defaultLauncher = Join-Path $repoRoot "Start-UniversalCopyPaste.cmd"
$adminLauncher = Join-Path $repoRoot "Start-UniversalCopyPaste-Admin.cmd"
$startupInstaller = Join-Path $repoRoot "Install-UniversalCopyPaste-Startup.ps1"
$startupLauncher = Join-Path $repoRoot "Install-UniversalCopyPaste-Startup.cmd"
$licensePath = Join-Path $repoRoot "LICENSE"

Describe "Universal Copy/Paste repository" {
    It "includes the release files" {
        @(
            $mainScript
            $defaultLauncher
            $adminLauncher
            $startupInstaller
            $startupLauncher
            $licensePath
            (Join-Path $repoRoot "README.md")
            (Join-Path $repoRoot "AUTHORS.md")
        ) | ForEach-Object {
            Test-Path $_ | Should Be $true
        }
    }

    It "uses the required MIT license text" {
        $license = Get-Content -Raw $licensePath

        $license | Should Match "MIT License"
        $license | Should Match "Copyright \(c\) 2026 Kitsune Technologies LLC"
        $license | Should Match "Permission is hereby granted, free of charge"
        $license | Should Match "THE SOFTWARE IS PROVIDED `"AS IS`""
    }

    It "keeps required generated and local files ignored" {
        $ignore = Get-Content -Raw (Join-Path $repoRoot ".gitignore")

        @(
            ".env"
            "node_modules/"
            ".venv/"
            "target/"
            "build/"
            ".oss31/"
        ) | ForEach-Object {
            $ignore | Should Match ([regex]::Escape($_))
        }
    }
}

Describe "Universal Copy/Paste launchers" {
    It "starts the main script through PowerShell STA mode" {
        $launcher = Get-Content -Raw $defaultLauncher

        $launcher | Should Match "UniversalCopyPaste\.ps1"
        $launcher | Should Match "-STA"
        $launcher | Should Match "-ExecutionPolicy Bypass"
    }

    It "has an administrator launcher for elevated apps" {
        $launcher = Get-Content -Raw $adminLauncher

        $launcher | Should Match "UniversalCopyPaste\.ps1"
        $launcher | Should Match "-Verb RunAs"
        $launcher | Should Match "-STA"
    }

    It "installs a startup shortcut to the default launcher" {
        $installer = Get-Content -Raw $startupInstaller
        $launcher = Get-Content -Raw $startupLauncher

        $installer | Should Match "Start-UniversalCopyPaste\.cmd"
        $installer | Should Match "Universal Copy Paste\.lnk"
        $launcher | Should Match "Install-UniversalCopyPaste-Startup\.ps1"
    }
}

Describe "Universal Copy/Paste user path wiring" {
    It "maps the documented hotkeys to backup copy, paste, toggle, and exit" {
        $script = Get-Content -Raw $mainScript

        $script | Should Match "ctrl && alt && !shift && vkCode == VK_C"
        $script | Should Match "BackupCopyAfterNativeCopy\(before\)"
        $script | Should Match "ctrl && alt && !shift && vkCode == VK_V"
        $script | Should Match "PasteClipboardTextAfterKeysRelease"
        $script | Should Match "ctrl && alt && shift && vkCode == VK_V"
        $script | Should Match "ToggleEnabled\(\)"
        $script | Should Match "ctrl && alt && shift && vkCode == VK_ESCAPE"
        $script | Should Match "Application\.Exit\(\)"
    }
}

Describe "Universal Copy/Paste compile smoke" {
    It "compiles on Windows and fails fast elsewhere" {
        $powerShellExe = if ($PSVersionTable.PSEdition -eq "Core") {
            (Get-Command pwsh).Source
        } else {
            (Get-Command powershell.exe).Source
        }

        $arguments = @("-NoProfile", "-ExecutionPolicy", "Bypass")
        if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) {
            $arguments += "-STA"
        }

        $arguments += @("-File", $mainScript, "-CompileOnly")
        $output = & $powerShellExe @arguments 2>&1
        $exitCode = $LASTEXITCODE

        if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) {
            $exitCode | Should Be 0
            ($output -join "`n") | Should Match "UniversalCopyPaste compiled successfully"
        } else {
            $exitCode | Should Not Be 0
            ($output -join "`n") | Should Match "UniversalCopyPaste only supports Windows"
        }
    }
}
