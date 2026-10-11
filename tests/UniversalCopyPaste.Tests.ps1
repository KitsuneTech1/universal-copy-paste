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

Describe "Universal Copy/Paste compile smoke" {
    It "compiles the inline helper in compile-only mode" {
        $output = & powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File $mainScript -CompileOnly 2>&1
        $exitCode = $LASTEXITCODE

        $exitCode | Should Be 0
        ($output -join "`n") | Should Match "UniversalCopyPaste compiled successfully"
    }
}
