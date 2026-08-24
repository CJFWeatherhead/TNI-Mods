# Copies this mod straight into the game's live mods folder.
# The game loads from user://mods/<id>/, so a copy + restart is all that is needed --
# no version bump, and no going through ModManager.
#
#   .\deploy.ps1            copy and report
#   .\deploy.ps1 -Watch     keep copying whenever a file changes
param([switch]$Watch)

$src = $PSScriptRoot
$dst = Join-Path $env:APPDATA "Godot\app_userdata\Tower Networking Inc\mods\cart-saver"
$files = @("entry.lua", "mod.jsonc", "metadata.yaml", "README.md", "icon.png")

function Copy-Mod {
    if (-not (Test-Path $dst)) { New-Item -ItemType Directory -Force $dst | Out-Null }
    foreach ($f in $files) {
        $p = Join-Path $src $f
        if (Test-Path $p) { Copy-Item $p $dst -Force }
    }
    $v = (Select-String -Path (Join-Path $src "entry.lua") -Pattern 'MOD_VER\s*=\s*"([^"]+)"').Matches[0].Groups[1].Value
    Write-Host ("deployed v{0} -> {1}  ({2})" -f $v, $dst, (Get-Date -Format "HH:mm:ss"))
}

Copy-Mod
if (-not $Watch) {
    Write-Host "Restart the game (or reload the save) to pick it up."
    return
}

Write-Host "Watching for changes. Ctrl+C to stop."
$last = @{}
while ($true) {
    foreach ($f in $files) {
        $p = Join-Path $src $f
        if (Test-Path $p) {
            $t = (Get-Item $p).LastWriteTimeUtc
            if ($last[$f] -ne $t) { $last[$f] = $t; $changed = $true }
        }
    }
    if ($changed) { Copy-Mod; $changed = $false }
    Start-Sleep -Seconds 2
}
