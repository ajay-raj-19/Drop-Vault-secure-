param([switch]$SkipBuild)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location -LiteralPath $projectRoot
try {
    if (-not $SkipBuild) {
        & flutter build windows --release
        if ($LASTEXITCODE -ne 0) { throw 'Windows release build failed.' }
    }

    $releaseDir = Join-Path $projectRoot 'build\windows\x64\runner\Release'
    if (-not (Test-Path -LiteralPath (Join-Path $releaseDir 'drop_vault.exe'))) {
        throw 'Build the Windows release before packaging the installer.'
    }

    # Bundle the supported app-local C++ runtime with this x64 release.
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    $vsPath = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if (-not $vsPath) { throw 'Visual Studio C++ build tools are required.' }
    $redistRoot = Join-Path $vsPath 'VC\Redist\MSVC'
    $crt = Get-ChildItem -LiteralPath $redistRoot -Directory |
        Where-Object Name -Match '^\d+\.\d+\.\d+$' |
        Sort-Object { [version]$_.Name } -Descending |
        ForEach-Object { Join-Path $_.FullName 'x64\Microsoft.VC143.CRT' } |
        Where-Object { Test-Path -LiteralPath $_ } |
        Select-Object -First 1
    if (-not $crt) { throw 'The x64 C++ redistributable files were not found.' }
    Get-ChildItem -LiteralPath $crt -Filter '*.dll' |
        Copy-Item -Destination $releaseDir -Force

    $compiler = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\ISCC.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe')
    ) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if (-not $compiler) { throw 'Install Inno Setup 6 before packaging.' }
    & $compiler (Join-Path $PSScriptRoot 'windows_installer.iss')
    if ($LASTEXITCODE -ne 0) { throw 'Windows installer compilation failed.' }
    Write-Output (Join-Path $projectRoot 'build\installer\DropVault_Setup.exe')
} finally {
    Pop-Location
}
