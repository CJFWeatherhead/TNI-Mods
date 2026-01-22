#!/usr/bin/env pwsh
<#
.SYNOPSIS
    The Network Inc - Mod Manager
.DESCRIPTION
    A PowerShell-based mod manager for configuring and managing TNI mods.
    Provides an interactive interface for enabling/disabling mods and adjusting parameters.
.NOTES
    Author: Chris
    Version: 1.0
    Requires: PowerShell 5.1 or higher
#>

#Requires -Version 5.1

# Configuration
$script:ModsDirectory = Join-Path $PSScriptRoot "lua"
$script:GameModsDirectory = "$env:APPDATA\Godot\app_userdata\Tower Networking Inc\mods"

# Colors
$script:Colors = @{
    Title     = "Cyan"
    Header    = "Yellow"
    Success   = "Green"
    Error     = "Red"
    Warning   = "DarkYellow"
    Info      = "Gray"
    Highlight = "White"
    Prompt    = "Magenta"
}

# Helper Functions
function Write-ColorText {
    param(
        [string]$Text,
        [string]$Color = "White",
        [switch]$NoNewline
    )
    Write-Host $Text -ForegroundColor $Color -NoNewline:$NoNewline
}

function Write-Title {
    param([string]$Text)
    Clear-Host
    Write-Host ""
    Write-ColorText "═══════════════════════════════════════════════════════════════" $script:Colors.Title
    Write-Host ""
    Write-ColorText "  $Text" $script:Colors.Title
    Write-Host ""
    Write-ColorText "═══════════════════════════════════════════════════════════════" $script:Colors.Title
    Write-Host ""
}

function Read-Choice {
    param(
        [string]$Prompt,
        [string[]]$Options,
        [string]$Default = ""
    )
    
    Write-Host ""
    Write-ColorText $Prompt $script:Colors.Prompt
    Write-Host ""
    
    for ($i = 0; $i -lt $Options.Count; $i++) {
        $displayNum = $i + 1
        Write-ColorText "  [$displayNum] " $script:Colors.Highlight -NoNewline
        Write-Host $Options[$i]
    }
    
    if ($Default) {
        Write-Host ""
        Write-ColorText "  [Enter] " $script:Colors.Highlight -NoNewline
        Write-Host $Default
    }
    
    Write-Host ""
    Write-ColorText "Choice: " $script:Colors.Prompt -NoNewline
    $choice = Read-Host
    
    if ([string]::IsNullOrWhiteSpace($choice) -and $Default) {
        return -1
    }
    
    $num = 0
    if ([int]::TryParse($choice, [ref]$num) -and $num -ge 1 -and $num -le $Options.Count) {
        return $num - 1
    }
    
    return -2
}

function Pause-ForUser {
    Write-Host ""
    Write-ColorText "Press any key to continue..." $script:Colors.Info
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# YAML Parser (simple implementation for metadata files)
function ConvertFrom-SimpleYaml {
    param([string]$Content)
    
    $result = @{}
    $lines = $Content -split "`r?`n"
    $currentKey = $null
    $multilineValue = @()
    $inMultiline = $false
    $inParameters = $false
    $parameters = @()
    $currentParam = $null
    
    foreach ($line in $lines) {
        # Skip empty lines and comments
        if ([string]::IsNullOrWhiteSpace($line) -or $line.Trim().StartsWith('#')) {
            continue
        }
        
        # Check for multiline start (|)
        if ($line -match '^(\w+):\s*\|') {
            $currentKey = $Matches[1]
            $inMultiline = $true
            $multilineValue = @()
            continue
        }
        
        # Handle multiline content
        if ($inMultiline) {
            if ($line -match '^\s{2,}(.+)') {
                $multilineValue += $Matches[1]
            }
            else {
                # End of multiline
                $result[$currentKey] = $multilineValue -join "`n"
                $inMultiline = $false
                $currentKey = $null
            }
        }
        
        # Check for Parameters section
        if ($line -match '^Parameters:\s*$') {
            $inParameters = $true
            continue
        }
        
        # Handle parameter entries
        if ($inParameters -and $line -match '^\s{2}-\s+Name:\s*(.+)') {
            if ($currentParam) {
                $parameters += $currentParam
            }
            $currentParam = @{ Name = $Matches[1].Trim() }
            continue
        }
        
        if ($inParameters -and $currentParam -and $line -match '^\s{4}(\w+):\s*(.*)') {
            $paramKey = $Matches[1]
            $paramValue = $Matches[2].Trim()
            
            # Remove quotes
            if ($paramValue -match '^"(.*)"$') {
                $paramValue = $Matches[1]
            }
            
            # Parse value types
            if ($paramValue -eq 'true') { $paramValue = $true }
            elseif ($paramValue -eq 'false') { $paramValue = $false }
            elseif ($paramValue -match '^\d+$') { $paramValue = [int]$paramValue }
            elseif ($paramValue -match '^\d+\.\d+$') { $paramValue = [double]$paramValue }
            elseif ($paramValue -match '^\[(.*)\]$') {
                # Parse array
                $paramValue = $Matches[1] -split ',\s*' | ForEach-Object { 
                    $_.Trim().Trim('"') 
                }
            }
            
            $currentParam[$paramKey] = $paramValue
            continue
        }
        
        # Regular key: value
        if ($line -match '^(\w+(?:\s+\w+)*):\s*(.*)') {
            $key = $Matches[1]
            $value = $Matches[2].Trim()
            
            # Remove quotes
            if ($value -match '^"(.*)"$') {
                $value = $Matches[1]
            }
            
            # Parse value types
            if ($value -eq 'true') { $value = $true }
            elseif ($value -eq 'false') { $value = $false }
            elseif ($value -match '^\d+$') { $value = [int]$value }
            elseif ($value -match '^\d+\.\d+$') { $value = [double]$value }
            elseif ($value -eq '[]' -or $value -eq '') { $value = @() }
            
            $result[$key] = $value
        }
    }
    
    # Add last parameter if any
    if ($currentParam) {
        $parameters += $currentParam
    }
    
    # Add last multiline if any
    if ($inMultiline -and $currentKey) {
        $result[$currentKey] = $multilineValue -join "`n"
    }
    
    if ($parameters.Count -gt 0) {
        $result['Parameters'] = $parameters
    }
    
    return $result
}

# Get mod parameters from ui-config.ps1 or metadata.yaml
function Get-ModParameters {
    param(
        [hashtable]$Mod,
        [hashtable]$CurrentConfig = @{}
    )
    
    $modFolder = $Mod['Folder']
    $modPath = Join-Path $script:ModsDirectory $modFolder
    
    # Check for ui-config.ps1 first (new approach)
    $uiConfigPath = Join-Path $modPath "ui-config.ps1"
    
    if (Test-Path $uiConfigPath) {
        Write-ColorText "Loading UI config from ui-config.ps1..." $script:Colors.Info
        try {
            # Execute the ui-config.ps1 script with current configuration
            $parameters = & $uiConfigPath -CurrentConfig $CurrentConfig
            
            if ($parameters -and $parameters.Count -gt 0) {
                Write-ColorText "Successfully loaded $($parameters.Count) parameters from ui-config.ps1" $script:Colors.Success
                return $parameters
            }
            else {
                Write-ColorText "ui-config.ps1 returned no parameters, falling back to metadata.yaml" $script:Colors.Warning
            }
        }
        catch {
            Write-ColorText "ERROR: Failed to execute ui-config.ps1: $_" $script:Colors.Error
            Write-ColorText "Falling back to metadata.yaml Parameters" $script:Colors.Warning
        }
    }
    
    # Fall back to metadata.yaml Parameters section (legacy approach)
    if ($Mod.ContainsKey('Parameters') -and $Mod['Parameters'].Count -gt 0) {
        return $Mod['Parameters']
    }
    
    return @()
}

# Mod Discovery
function Get-InstalledMods {
    $mods = @()
    
    if (-not (Test-Path $script:ModsDirectory)) {
        Write-ColorText "ERROR: Mods directory not found: $script:ModsDirectory" $script:Colors.Error
        return $mods
    }
    
    $modFolders = Get-ChildItem -Path $script:ModsDirectory -Directory | 
    Where-Object { $_.Name -ne '.lua-typing' }
    
    foreach ($folder in $modFolders) {
        $metadataPath = Join-Path $folder.FullName "metadata.yaml"
        
        if (Test-Path $metadataPath) {
            try {
                $content = Get-Content $metadataPath -Raw
                $metadata = ConvertFrom-SimpleYaml $content
                $metadata['Folder'] = $folder.Name
                $mods += $metadata
            }
            catch {
                Write-ColorText "WARNING: Failed to parse metadata for $($folder.Name)" $script:Colors.Warning
            }
        }
    }
    
    return $mods
}

# Configuration Management
function Get-ModConfigPath {
    param($ModId)
    return Join-Path $script:ModsDirectory "$ModId\entry.lua"
}

function Get-ModConfig {
    param($ModId)
    
    $entryPath = Get-ModConfigPath $ModId
    
    if (-not (Test-Path $entryPath)) {
        Write-ColorText "WARNING: entry.lua not found for $ModId" $script:Colors.Warning
        return @{}
    }
    
    try {
        $config = @{}
        $content = Get-Content $entryPath -Raw
        
        # Find config section between markers
        if ($content -match '(?s)-- ===== MOD CONFIGURATION START =====.*?local config = \{(.*?)\}.*?-- ===== MOD CONFIGURATION END =====') {
            $configBlock = $Matches[1]
            
            # Parse each line in the config block
            foreach ($line in ($configBlock -split "`n")) {
                $line = $line.Trim()
                
                # Skip comments and empty lines
                if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('--')) {
                    continue
                }
                
                # Parse key = value, (handle inline comments)
                if ($line -match '^\s*(\w+)\s*=\s*(.+?),?\s*(--.*)?$') {
                    $key = $Matches[1]
                    $value = $Matches[2].TrimEnd(',').Trim()
                    
                    # Remove inline comments from value
                    $value = $value -replace '\s*--.*$', ''
                    $value = $value.Trim().TrimEnd(',')
                    
                    # Parse value types
                    if ($value -eq 'true') { $config[$key] = $true }
                    elseif ($value -eq 'false') { $config[$key] = $false }
                    elseif ($value -match '^-?\d+$') { $config[$key] = [int]$value }
                    elseif ($value -match '^-?\d+\.?\d*$') { $config[$key] = [double]$value }
                    elseif ($value -match '^"(.*)"$') { $config[$key] = $Matches[1] }
                    else { $config[$key] = $value.Trim('"') }
                }
            }
        }
        
        return $config
    }
    catch {
        Write-ColorText "WARNING: Failed to parse config for $ModId : $_" $script:Colors.Warning
        return @{}
    }
}

function Save-ModConfig {
    param($ModId, $Config)
    
    try {
        $entryPath = Get-ModConfigPath $ModId
        
        if (-not (Test-Path $entryPath)) {
            Write-ColorText "ERROR: entry.lua not found for $ModId" $script:Colors.Error
            return $false
        }
        
        # Read the current file
        $content = Get-Content $entryPath -Raw
        
        # Find the config section
        if ($content -match '(?s)(-- ===== MOD CONFIGURATION START =====.*?local config = \{)(.*?)(\}.*?-- ===== MOD CONFIGURATION END =====)') {
            $prefix = $Matches[1]
            $oldConfigBlock = $Matches[2]
            $suffix = $Matches[3]
            
            # Build new config block
            $newConfigLines = @()
            $sortedKeys = $Config.Keys | Sort-Object
            
            foreach ($key in $sortedKeys) {
                $value = $Config[$key]
                
                # Format value based on type
                if ($value -is [bool]) {
                    $formattedValue = $value.ToString().ToLower()
                }
                elseif ($value -is [int] -or $value -is [long]) {
                    $formattedValue = $value.ToString()
                }
                elseif ($value -is [double] -or $value -is [float]) {
                    $formattedValue = $value.ToString('0.0#####')
                }
                elseif ($value -is [string]) {
                    $formattedValue = "`"$value`""
                }
                else {
                    $formattedValue = "`"$value`""
                }
                
                $newConfigLines += "    $key = $formattedValue,"
            }
            
            # Join with newlines and add proper indentation
            $newConfigBlock = "`n" + ($newConfigLines -join "`n") + "`n"
            
            # Replace the config block
            $newContent = $prefix + $newConfigBlock + $suffix
            
            # Write back to file with UTF-8 without BOM
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($entryPath, $newContent, $utf8NoBom)
            
            return $true
        }
        else {
            Write-ColorText "ERROR: Could not find config section in entry.lua for $ModId" $script:Colors.Error
            return $false
        }
    }
    catch {
        Write-ColorText "ERROR: Failed to save config for $ModId : $_" $script:Colors.Error
        Write-ColorText "Details: $($_.Exception.Message)" $script:Colors.Error
        return $false
    }
}

function Get-ModParameter {
    param($ModId, $ParamName, $Default)
    
    $config = Get-ModConfig $ModId
    
    if ($config.ContainsKey($ParamName)) {
        return $config[$ParamName]
    }
    
    return $Default
}

function Set-ModParameter {
    param($ModId, $ParamName, $Value)
    
    $config = Get-ModConfig $ModId
    $config[$ParamName] = $Value
    Save-ModConfig $ModId $config
}

# UI Functions
function Show-MainMenu {
    $mods = Get-InstalledMods
    
    while ($true) {
        Write-Title "THE NETWORK INC - MOD MANAGER"
        
        Write-ColorText "Installed Mods: " $script:Colors.Header -NoNewline
        Write-Host "$($mods.Count)"
        Write-ColorText "Config Location: " $script:Colors.Header -NoNewline
        Write-Host $script:GameModsDirectory
        
        Write-Host ""
        Write-ColorText "══════════════════════════════════════" $script:Colors.Info
        Write-Host ""
        
        if ($mods.Count -eq 0) {
            Write-ColorText "No mods found in: $script:ModsDirectory" $script:Colors.Warning
            Write-Host ""
        }
        else {
            foreach ($mod in $mods) {
                $config = Get-ModConfig $mod['ID']
                $enabled = $config.ContainsKey('_enabled') -and $config['_enabled'] -eq $false
                $enabled = -not $enabled # Invert: if _enabled=false, show disabled
                
                $status = if ($enabled) { 
                    Write-ColorText "✓ ENABLED " $script:Colors.Success -NoNewline
                }
                else { 
                    Write-ColorText "✗ DISABLED" $script:Colors.Error -NoNewline
                }
                
                Write-ColorText " │ " $script:Colors.Info -NoNewline
                Write-ColorText $mod['Name'] $script:Colors.Highlight
                
                $hasParams = $mod.ContainsKey('Parameters') -and $mod['Parameters'].Count -gt 0
                if ($hasParams) {
                    Write-ColorText "   └─ " $script:Colors.Info -NoNewline
                    Write-ColorText "$($mod['Parameters'].Count) configurable parameter(s)" $script:Colors.Info
                }
            }
        }
        
        $options = @(
            "View & Configure Mods"
            "Enable/Disable Mods"
            "Reset Mod to Defaults"
            "Refresh Mod List"
            "Exit"
        )
        
        $choice = Read-Choice "Select an option:" $options
        
        switch ($choice) {
            0 { Show-ModListMenu $mods }
            1 { Show-EnableDisableMenu $mods }
            2 { Show-ResetMenu $mods }
            3 { continue }
            4 { return }
            -2 { 
                Write-ColorText "Invalid choice!" $script:Colors.Error
                Start-Sleep -Seconds 1
            }
        }
    }
}

function Show-ModListMenu {
    param($Mods)
    
    while ($true) {
        Write-Title "MOD LIST & CONFIGURATION"
        
        Write-Host "Select a mod to view details and configure:"
        Write-Host ""
        
        $modNames = $Mods | ForEach-Object { 
            $config = Get-ModConfig $_['ID']
            $enabled = -not ($config.ContainsKey('_enabled') -and $config['_enabled'] -eq $false)
            $status = if ($enabled) { "[✓]" } else { "[✗]" }
            "$status $($_['Name'])"
        }
        $modNames += "◄ Back to Main Menu"
        
        $choice = Read-Choice "Select mod:" $modNames
        
        if ($choice -eq $Mods.Count) { return }
        if ($choice -lt 0 -or $choice -ge $Mods.Count) {
            Write-ColorText "Invalid choice!" $script:Colors.Error
            Start-Sleep -Seconds 1
            continue
        }
        
        Show-ModDetailMenu $Mods[$choice]
    }
}

function Show-ModDetailMenu {
    param($Mod)
    
    while ($true) {
        Write-Title $Mod['Name']
        
        $config = Get-ModConfig $Mod['ID']
        $enabled = -not ($config.ContainsKey('_enabled') -and $config['_enabled'] -eq $false)
        
        Write-ColorText "Status: " $script:Colors.Header -NoNewline
        if ($enabled) {
            Write-ColorText "ENABLED" $script:Colors.Success
        }
        else {
            Write-ColorText "DISABLED" $script:Colors.Error
        }
        
        Write-ColorText "ID: " $script:Colors.Header -NoNewline
        Write-Host $Mod['ID']
        
        Write-ColorText "Author: " $script:Colors.Header -NoNewline
        Write-Host $Mod['Author']
        
        Write-ColorText "Version: " $script:Colors.Header -NoNewline
        Write-Host "$($Mod['Development Status']) | Game: $($Mod['Game Version Supported'])"
        
        if ($Mod['Description']) {
            Write-Host ""
            Write-ColorText "Description:" $script:Colors.Header
            Write-Host $Mod['Description']
        }
        
        if ($Mod['Notes']) {
            Write-Host ""
            Write-ColorText "Notes:" $script:Colors.Header
            Write-Host $Mod['Notes']
        }
        
        $options = @(
            "Toggle Enable/Disable"
        )
        
        # Get parameters using new function (supports ui-config.ps1 or metadata.yaml)
        $currentConfig = Get-ModConfig $Mod['ID']
        $parameters = Get-ModParameters -Mod $Mod -CurrentConfig $currentConfig
        
        if ($parameters -and $parameters.Count -gt 0) {
            # Count only actual parameters (not sections/info/warning elements)
            $paramCount = ($parameters | Where-Object { 
                    -not $_.ContainsKey('Type') -or 
                    ($_.Type -notin @('section', 'info', 'warning'))
                }).Count
            $options += "Configure Parameters ($paramCount)"
        }
        
        $options += "◄ Back"
        
        $choice = Read-Choice "Select action:" $options
        
        if ($choice -eq 0) {
            $config['_enabled'] = $enabled  # Store current state before toggle
            $config['_enabled'] = -not $enabled
            Save-ModConfig $Mod['ID'] $config
            Write-ColorText "✓ Configuration saved" $script:Colors.Success
            Start-Sleep -Seconds 1
        }
        elseif ($choice -eq 1 -and $parameters -and $parameters.Count -gt 0) {
            Show-ParameterConfigMenu $Mod $parameters
        }
        elseif ($choice -eq $options.Count - 1) {
            return
        }
    }
}

function Show-ParameterConfigMenu {
    param(
        [hashtable]$Mod,
        [array]$Parameters
    )
    
    while ($true) {
        Write-Title "$($Mod['Name']) - Parameters"
        
        # Reload parameters each time to support dynamic UI
        $currentConfig = Get-ModConfig $Mod['ID']
        $Parameters = Get-ModParameters -Mod $Mod -CurrentConfig $currentConfig
        
        Write-Host "Current Configuration:"
        Write-Host ""
        
        # Display parameters, handling special types (section, info, warning)
        foreach ($param in $Parameters) {
            # Handle section headers
            if ($param.ContainsKey('Type') -and $param['Type'] -eq 'section') {
                Write-Host ""
                Write-ColorText "═══ $($param['Label']) ═══" $script:Colors.Title
                if ($param.ContainsKey('Description')) {
                    Write-ColorText "    $($param['Description'])" $script:Colors.Info
                }
                Write-Host ""
                continue
            }
            
            # Handle info messages
            if ($param.ContainsKey('Type') -and $param['Type'] -eq 'info') {
                Write-ColorText "    ℹ $($param['Message'])" $script:Colors.Info
                Write-Host ""
                continue
            }
            
            # Handle warning messages
            if ($param.ContainsKey('Type') -and $param['Type'] -eq 'warning') {
                Write-ColorText "    ⚠ $($param['Message'])" $script:Colors.Warning
                Write-Host ""
                continue
            }
            
            # Skip invisible parameters
            if ($param.ContainsKey('Visible') -and -not $param['Visible']) {
                continue
            }
            
            # Display regular parameters
            $currentValue = Get-ModParameter $Mod['ID'] $param['Name'] $param['Default']
            
            Write-ColorText "  • " $script:Colors.Highlight -NoNewline
            Write-ColorText "$($param['Label'])" $script:Colors.Header
            Write-ColorText "    Current: " $script:Colors.Info -NoNewline
            Write-ColorText $currentValue $script:Colors.Success
            Write-ColorText "    Default: " $script:Colors.Info -NoNewline
            Write-Host "$($param['Default']) ($($param['Type']))"
            
            if ($param['Description']) {
                Write-ColorText "    " $script:Colors.Info -NoNewline
                Write-Host $param['Description']
            }
            Write-Host ""
        }
        
        # Build options list (only for editable parameters)
        $options = @()
        $editableParams = @()
        foreach ($param in $Parameters) {
            # Only include actual parameters (not sections/info/warning)
            if (-not $param.ContainsKey('Type') -or 
                $param['Type'] -notin @('section', 'info', 'warning')) {
                # Skip invisible parameters
                if ($param.ContainsKey('Visible') -and -not $param['Visible']) {
                    continue
                }
                $options += "Edit: $($param['Label'])"
                $editableParams += $param
            }
        }
        $options += "Reset All to Defaults"
        $options += "◄ Back"
        
        $choice = Read-Choice "Select parameter to edit:" $options
        
        if ($choice -ge 0 -and $choice -lt $editableParams.Count) {
            Edit-Parameter $Mod $editableParams[$choice]
        }
        elseif ($choice -eq $editableParams.Count) {
            # Reset all
            $config = Get-ModConfig $Mod['ID']
            foreach ($param in $editableParams) {
                $config[$param['Name']] = $param['Default']
            }
            Save-ModConfig $Mod['ID'] $config
            Write-ColorText "✓ All parameters reset to defaults" $script:Colors.Success
            Start-Sleep -Seconds 1
        }
        elseif ($choice -eq $options.Count - 1) {
            return
        }
    }
}

function Edit-Parameter {
    param($Mod, $Param)
    
    Write-Title "Edit Parameter: $($Param['Label'])"
    
    $currentValue = Get-ModParameter $Mod['ID'] $Param['Name'] $Param['Default']
    
    Write-ColorText "Parameter: " $script:Colors.Header -NoNewline
    Write-Host $Param['Label']
    
    Write-ColorText "Description: " $script:Colors.Header -NoNewline
    Write-Host $Param['Description']
    
    Write-ColorText "Type: " $script:Colors.Header -NoNewline
    Write-Host $Param['Type']
    
    Write-ColorText "Current Value: " $script:Colors.Header -NoNewline
    Write-ColorText $currentValue $script:Colors.Success
    
    Write-ColorText "Default Value: " $script:Colors.Header -NoNewline
    Write-Host $Param['Default']
    
    if ($Param.ContainsKey('Min')) {
        Write-ColorText "Min: " $script:Colors.Info -NoNewline
        Write-Host $Param['Min']
    }
    
    if ($Param.ContainsKey('Max')) {
        Write-ColorText "Max: " $script:Colors.Info -NoNewline
        Write-Host $Param['Max']
    }
    
    Write-Host ""
    
    # Handle different parameter types
    $newValue = $null
    
    switch ($Param['Type']) {
        'boolean' {
            $options = @('true', 'false', 'Cancel')
            $choice = Read-Choice "Select value:" $options
            if ($choice -eq 0) { $newValue = $true }
            elseif ($choice -eq 1) { $newValue = $false }
            else { return }
        }
        
        'select' {
            $options = $Param['Options'] + @('Cancel')
            $choice = Read-Choice "Select value:" $options
            if ($choice -ge 0 -and $choice -lt $Param['Options'].Count) {
                $newValue = $Param['Options'][$choice]
            }
            else {
                return
            }
        }
        
        'integer' {
            Write-ColorText "Enter new value (or 'cancel'): " $script:Colors.Prompt -NoNewline
            $input = Read-Host
            
            if ($input -eq 'cancel') { return }
            
            $num = 0
            if ([int]::TryParse($input, [ref]$num)) {
                if ($Param.ContainsKey('Min') -and $num -lt $Param['Min']) {
                    Write-ColorText "Value below minimum ($($Param['Min']))!" $script:Colors.Error
                    Start-Sleep -Seconds 2
                    return
                }
                if ($Param.ContainsKey('Max') -and $num -gt $Param['Max']) {
                    Write-ColorText "Value above maximum ($($Param['Max']))!" $script:Colors.Error
                    Start-Sleep -Seconds 2
                    return
                }
                $newValue = $num
            }
            else {
                Write-ColorText "Invalid integer!" $script:Colors.Error
                Start-Sleep -Seconds 2
                return
            }
        }
        
        'number' {
            Write-ColorText "Enter new value (or 'cancel'): " $script:Colors.Prompt -NoNewline
            $input = Read-Host
            
            if ($input -eq 'cancel') { return }
            
            $num = 0.0
            if ([double]::TryParse($input, [ref]$num)) {
                if ($Param.ContainsKey('Min') -and $num -lt $Param['Min']) {
                    Write-ColorText "Value below minimum ($($Param['Min']))!" $script:Colors.Error
                    Start-Sleep -Seconds 2
                    return
                }
                if ($Param.ContainsKey('Max') -and $num -gt $Param['Max']) {
                    Write-ColorText "Value above maximum ($($Param['Max']))!" $script:Colors.Error
                    Start-Sleep -Seconds 2
                    return
                }
                $newValue = $num
            }
            else {
                Write-ColorText "Invalid number!" $script:Colors.Error
                Start-Sleep -Seconds 2
                return
            }
        }
        
        'string' {
            Write-ColorText "Enter new value (or 'cancel'): " $script:Colors.Prompt -NoNewline
            $input = Read-Host
            
            if ($input -eq 'cancel') { return }
            
            $newValue = $input
        }
    }
    
    if ($null -ne $newValue) {
        Set-ModParameter $Mod['ID'] $Param['Name'] $newValue
        Write-Host ""
        Write-ColorText "✓ Parameter updated: $currentValue → $newValue" $script:Colors.Success
        Start-Sleep -Seconds 1
    }
}

function Show-EnableDisableMenu {
    param($Mods)
    
    while ($true) {
        Write-Title "ENABLE/DISABLE MODS"
        
        Write-Host "Toggle mods on/off:"
        Write-Host ""
        
        for ($i = 0; $i -lt $Mods.Count; $i++) {
            $mod = $Mods[$i]
            $config = Get-ModConfig $mod['ID']
            $enabled = -not ($config.ContainsKey('_enabled') -and $config['_enabled'] -eq $false)
            
            $displayNum = $i + 1
            Write-ColorText "  [$displayNum] " $script:Colors.Highlight -NoNewline
            
            if ($enabled) {
                Write-ColorText "[✓] " $script:Colors.Success -NoNewline
            }
            else {
                Write-ColorText "[✗] " $script:Colors.Error -NoNewline
            }
            
            Write-Host $mod['Name']
        }
        
        Write-Host ""
        Write-ColorText "  [A] " $script:Colors.Highlight -NoNewline
        Write-Host "Enable All"
        
        Write-ColorText "  [D] " $script:Colors.Highlight -NoNewline
        Write-Host "Disable All"
        
        Write-ColorText "  [B] " $script:Colors.Highlight -NoNewline
        Write-Host "Back"
        
        Write-Host ""
        Write-ColorText "Enter choice (number, A, D, or B): " $script:Colors.Prompt -NoNewline
        $choice = Read-Host
        
        if ($choice -eq 'B' -or $choice -eq 'b') {
            return
        }
        elseif ($choice -eq 'A' -or $choice -eq 'a') {
            foreach ($mod in $Mods) {
                $config = Get-ModConfig $mod['ID']
                $config['_enabled'] = $true
                Save-ModConfig $mod['ID'] $config
            }
            Write-ColorText "✓ All mods enabled" $script:Colors.Success
            Start-Sleep -Seconds 1
        }
        elseif ($choice -eq 'D' -or $choice -eq 'd') {
            foreach ($mod in $Mods) {
                $config = Get-ModConfig $mod['ID']
                $config['_enabled'] = $false
                Save-ModConfig $mod['ID'] $config
            }
            Write-ColorText "✓ All mods disabled" $script:Colors.Success
            Start-Sleep -Seconds 1
        }
        else {
            $num = 0
            if ([int]::TryParse($choice, [ref]$num) -and $num -ge 1 -and $num -le $Mods.Count) {
                $mod = $Mods[$num - 1]
                $config = Get-ModConfig $mod['ID']
                $currentEnabled = -not ($config.ContainsKey('_enabled') -and $config['_enabled'] -eq $false)
                $config['_enabled'] = -not $currentEnabled
                Save-ModConfig $mod['ID'] $config
                
                $status = if (-not $currentEnabled) { "enabled" } else { "disabled" }
                Write-ColorText "✓ $($mod['Name']) $status" $script:Colors.Success
                Start-Sleep -Seconds 1
            }
            else {
                Write-ColorText "Invalid choice!" $script:Colors.Error
                Start-Sleep -Seconds 1
            }
        }
    }
}

function Show-ResetMenu {
    param($Mods)
    
    Write-Title "RESET MOD TO DEFAULTS"
    
    Write-Host "Select a mod to reset:"
    Write-Host ""
    
    $modNames = $Mods | ForEach-Object { $_['Name'] }
    $modNames += "◄ Cancel"
    
    $choice = Read-Choice "Select mod:" $modNames
    
    if ($choice -lt 0 -or $choice -ge $Mods.Count) {
        return
    }
    
    $mod = $Mods[$choice]
    
    Write-Host ""
    Write-ColorText "WARNING: This will reset ALL parameters for '$($mod['Name'])' to defaults!" $script:Colors.Warning
    Write-Host ""
    Write-ColorText "Are you sure? (yes/no): " $script:Colors.Prompt -NoNewline
    $confirm = Read-Host
    
    if ($confirm -eq 'yes') {
        $configPath = Get-ModConfigPath $mod['ID']
        if (Test-Path $configPath) {
            Remove-Item $configPath -Force
        }
        Write-Host ""
        Write-ColorText "✓ Configuration reset to defaults for $($mod['Name'])" $script:Colors.Success
        Start-Sleep -Seconds 2
    }
    else {
        Write-ColorText "Cancelled" $script:Colors.Info
        Start-Sleep -Seconds 1
    }
}

# Main Entry Point
try {
    Write-Title "THE NETWORK INC - MOD MANAGER"
    Write-Host "Initializing..."
    Start-Sleep -Milliseconds 500
    
    # Verify mods directory exists
    if (-not (Test-Path $script:ModsDirectory)) {
        Write-ColorText "ERROR: Mods directory not found!" $script:Colors.Error
        Write-Host "Expected location: $script:ModsDirectory"
        Write-Host ""
        Write-Host "Please run this script from the TNI-Mods directory."
        Pause-ForUser
        exit 1
    }
    
    # Show main menu
    Show-MainMenu
    
    Write-Host ""
    Write-ColorText "Thank you for using TNI Mod Manager!" $script:Colors.Success
    Write-Host ""
}
catch {
    Write-ColorText "FATAL ERROR: $_" $script:Colors.Error
    Write-Host $_.ScriptStackTrace
    Pause-ForUser
    exit 1
}
