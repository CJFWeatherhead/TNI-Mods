#Requires -Version 5.1

<#
.SYNOPSIS
    The Network Inc - WPF Mod Manager v3.5.2
.DESCRIPTION
    A Windows Presentation Foundation GUI for managing TNI mods.
    Downloads mods from GitHub releases, manages local mods, and configures parameters.
.NOTES
    Author: CJFWeatherhead
    Version: 3.5.3
    Requires: PowerShell 5.1+, .NET Framework 4.5+
#>

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# Configuration
$script:AppDataPath = [Environment]::GetFolderPath('ApplicationData')
$script:GameDataPath = Join-Path $script:AppDataPath "Godot\app_userdata\Tower Networking Inc"
$script:ModsDirectory = Join-Path $script:GameDataPath "Mods"
$script:DisabledModsDirectory = Join-Path $script:GameDataPath "Mods_Disabled"
$script:SettingsPath = Join-Path $script:GameDataPath "settings.json"
$script:ModCachePath = Join-Path $script:GameDataPath "mod_cache.json"
$script:ConfigFileName = "entry.lua"
$script:LuaJitPath = Join-Path $script:ModsDirectory "luajit.elf"

# GitHub Configuration
$script:GitHubRepo = "CJFWeatherhead/TNI-Mods"
$script:GitHubApiBase = "https://api.github.com/repos/$script:GitHubRepo"
$script:LuaJitReleaseTag = "continuous-gnu-beta"
$script:LuaJitZipUrl = "https://github.com/$script:GitHubRepo/releases/download/$script:LuaJitReleaseTag/luajit.zip"

# Startup logging
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "TNI Mod Manager v3.0 - Starting up..." -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Game Data Path:          " -NoNewline -ForegroundColor Gray
Write-Host $script:GameDataPath -ForegroundColor White
Write-Host "  Mods Directory:          " -NoNewline -ForegroundColor Gray
Write-Host $script:ModsDirectory -ForegroundColor White
Write-Host "  GitHub Repository:       " -NoNewline -ForegroundColor Gray
Write-Host $script:GitHubRepo -ForegroundColor White
Write-Host ""

# Verify paths exist
if (Test-Path $script:ModsDirectory) {
    Write-Host "[OK] Mods directory found" -ForegroundColor Green
}
else {
    Write-Host "[WARN] Mods directory not found - will be created when needed" -ForegroundColor Yellow
}
Write-Host ""

# Global state
$script:Config = $null
$script:InstalledMods = @()
$script:AllMods = @()
$script:GitHubReleases = @{}
$script:CurrentMod = $null
$script:Settings = $null
$script:CmdAliases = @{}
$script:ModCache = @{}
$script:IsDownloading = $false

# Mod source types
$script:ModSourceType = @{
    Downloaded = "Downloaded"
    Manual = "Manual"
    Available = "Available"
}

#region LuaJIT Management

function Test-LuaJitInstalled {
    <#
    .SYNOPSIS
        Checks if luajit.elf is installed in the mods directory
    #>
    return (Test-Path $script:LuaJitPath)
}

function Install-LuaJit {
    <#
    .SYNOPSIS
        Downloads and installs luajit.elf from GitHub releases
    #>
    param(
        [System.Windows.Controls.ProgressBar]$ProgressBar = $null,
        [System.Windows.Controls.TextBlock]$StatusText = $null
    )
    
    try {
        Write-Host "Downloading LuaJIT..." -ForegroundColor Cyan
        
        if ($StatusText) {
            $StatusText.Dispatcher.Invoke([Action]{
                $StatusText.Text = "Downloading LuaJIT..."
            })
        }
        
        if ($ProgressBar) {
            $ProgressBar.Dispatcher.Invoke([Action]{
                $ProgressBar.IsIndeterminate = $false
                $ProgressBar.Value = 0
                $ProgressBar.Visibility = "Visible"
            })
        }
        
        $tempZipPath = Join-Path $env:TEMP "luajit.zip"
        
        # Ensure mods directory exists
        if (-not (Test-Path $script:ModsDirectory)) {
            New-Item -Path $script:ModsDirectory -ItemType Directory -Force | Out-Null
        }
        
        # Download with progress using WebClient
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "TNI-ModManager/3.0")
        
        # Get file size
        $totalBytes = 0
        $downloadedBytes = 0
        
        try {
            $request = [System.Net.WebRequest]::Create($script:LuaJitZipUrl)
            $request.Method = "HEAD"
            $request.UserAgent = "TNI-ModManager/3.0"
            $response = $request.GetResponse()
            $totalBytes = $response.ContentLength
            $response.Close()
        }
        catch {
            Write-Host "  Could not determine file size, continuing anyway..." -ForegroundColor Yellow
        }
        
        # Download with progress tracking
        $stream = $webClient.OpenRead($script:LuaJitZipUrl)
        $fileStream = [System.IO.File]::Create($tempZipPath)
        $buffer = New-Object byte[] 8192
        $lastProgress = 0
        
        while (($read = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $fileStream.Write($buffer, 0, $read)
            $downloadedBytes += $read
            
            if ($totalBytes -gt 0 -and $ProgressBar) {
                $progress = [int](($downloadedBytes / $totalBytes) * 100)
                if ($progress -ne $lastProgress) {
                    $ProgressBar.Dispatcher.Invoke([Action]{
                        $ProgressBar.Value = $progress
                    })
                    $lastProgress = $progress
                }
            }
            
            # Allow UI to update
            [System.Windows.Forms.Application]::DoEvents()
        }
        
        $stream.Close()
        $fileStream.Close()
        $webClient.Dispose()
        
        if ($StatusText) {
            $StatusText.Dispatcher.Invoke([Action]{
                $StatusText.Text = "Extracting LuaJIT..."
            })
        }
        
        if ($ProgressBar) {
            $ProgressBar.Dispatcher.Invoke([Action]{
                $ProgressBar.IsIndeterminate = $true
            })
        }
        
        # Extract luajit.elf from zip
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip = [System.IO.Compression.ZipFile]::OpenRead($tempZipPath)
        
        $luajitEntry = $zip.Entries | Where-Object { $_.Name -eq "luajit.elf" } | Select-Object -First 1
        
        if ($luajitEntry) {
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($luajitEntry, $script:LuaJitPath, $true)
            Write-Host "  [OK] LuaJIT installed successfully" -ForegroundColor Green
            $success = $true
        }
        else {
            Write-Host "  [ERROR] luajit.elf not found in archive" -ForegroundColor Red
            $success = $false
        }
        
        $zip.Dispose()
        
        # Clean up temp file
        Remove-Item $tempZipPath -Force -ErrorAction SilentlyContinue
        
        if ($StatusText) {
            $StatusText.Dispatcher.Invoke([Action]{
                $StatusText.Text = if ($success) { "LuaJIT installed successfully!" } else { "LuaJIT installation failed" }
            })
        }
        
        if ($ProgressBar) {
            $ProgressBar.Dispatcher.Invoke([Action]{
                $ProgressBar.Visibility = "Collapsed"
            })
        }
        
        return $success
    }
    catch {
        Write-Host "[ERROR] LuaJIT installation failed: $_" -ForegroundColor Red
        
        if ($StatusText) {
            $StatusText.Dispatcher.Invoke([Action]{
                $StatusText.Text = "LuaJIT installation failed: $_"
            })
        }
        
        if ($ProgressBar) {
            $ProgressBar.Dispatcher.Invoke([Action]{
                $ProgressBar.Visibility = "Collapsed"
            })
        }
        
        return $false
    }
}

function Show-LuaJitPrompt {
    <#
    .SYNOPSIS
        Shows a prompt to the user about missing LuaJIT and offers to download it
    #>
    param(
        [System.Windows.Controls.ProgressBar]$ProgressBar = $null,
        [System.Windows.Controls.TextBlock]$StatusText = $null
    )
    
    $message = @"
LuaJIT Runtime Missing

The LuaJIT runtime (luajit.elf) is required to load Lua mods.
It was not found in your mods directory.

Would you like to download and install it now?

Location: $script:LuaJitPath
"@
    
    $result = [System.Windows.MessageBox]::Show(
        $message,
        "LuaJIT Required",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Question
    )
    
    if ($result -eq "Yes") {
        $installSuccess = Install-LuaJit -ProgressBar $ProgressBar -StatusText $StatusText
        
        if ($installSuccess) {
            [System.Windows.MessageBox]::Show(
                "LuaJIT has been installed successfully!`n`nYour mods should now load correctly.",
                "Installation Complete",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Information
            )
        }
        else {
            [System.Windows.MessageBox]::Show(
                "Failed to install LuaJIT.`n`nPlease download luajit.zip manually from:`n$script:LuaJitZipUrl`n`nExtract luajit.elf to:`n$script:LuaJitPath",
                "Installation Failed",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Error
            )
        }
        
        return $installSuccess
    }
    else {
        $warning = @"
Warning: Without LuaJIT, mods are unlikely to load correctly.

You can install it later by downloading luajit.zip from:
$script:LuaJitZipUrl

Extract luajit.elf to:
$script:LuaJitPath
"@
        
        [System.Windows.MessageBox]::Show(
            $warning,
            "LuaJIT Not Installed",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Warning
        )
        
        return $false
    }
}

#endregion

#region GitHub API Functions

function Get-GitHubReleases {
    <#
    .SYNOPSIS
        Fetches all mod releases from GitHub
    #>
    try {
        Write-Host "Fetching releases from GitHub..." -ForegroundColor Cyan
        
        $uri = "$script:GitHubApiBase/releases"
        $headers = @{
            "Accept" = "application/vnd.github.v3+json"
            "User-Agent" = "TNI-ModManager/3.0"
        }
        
        $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get -TimeoutSec 30
        
        $modReleases = @{}
        
        foreach ($release in $response) {
            # Parse release tag: format is <mod-id>-v<version>
            if ($release.tag_name -match '^(.+)-v(\d+\.\d+\.\d+)$') {
                $modId = $Matches[1]
                $version = $Matches[2]
                
                # Find the zip asset
                $asset = $release.assets | Where-Object { $_.name -like "*.zip" } | Select-Object -First 1
                
                if ($asset) {
                    $releaseInfo = @{
                        ModId = $modId
                        Version = $version
                        TagName = $release.tag_name
                        DownloadUrl = $asset.browser_download_url
                        AssetName = $asset.name
                        Size = $asset.size
                        PublishedAt = $release.published_at
                        ReleaseNotes = $release.body
                        HtmlUrl = $release.html_url
                    }
                    
                    # Keep only the latest version for each mod
                    if (-not $modReleases.ContainsKey($modId) -or 
                        (Compare-SemanticVersion $version $modReleases[$modId].Version) -gt 0) {
                        $modReleases[$modId] = $releaseInfo
                    }
                }
            }
        }
        
        Write-Host "  Found $($modReleases.Count) mod releases" -ForegroundColor Green
        return $modReleases
        
    }
    catch {
        Write-Host "[ERROR] Failed to fetch GitHub releases: $_" -ForegroundColor Red
        return @{}
    }
}

function Compare-SemanticVersion {
    <#
    .SYNOPSIS
        Compares two semantic versions. Returns 1 if v1 > v2, -1 if v1 < v2, 0 if equal
    #>
    param(
        [string]$Version1,
        [string]$Version2
    )
    
    try {
        $v1Parts = $Version1 -split '\.' | ForEach-Object { [int]$_ }
        $v2Parts = $Version2 -split '\.' | ForEach-Object { [int]$_ }
        
        for ($i = 0; $i -lt 3; $i++) {
            $v1 = if ($i -lt $v1Parts.Count) { $v1Parts[$i] } else { 0 }
            $v2 = if ($i -lt $v2Parts.Count) { $v2Parts[$i] } else { 0 }
            
            if ($v1 -gt $v2) { return 1 }
            if ($v1 -lt $v2) { return -1 }
        }
        
        return 0
    }
    catch {
        return 0
    }
}

function Download-ModFromGitHub {
    <#
    .SYNOPSIS
        Downloads and installs a mod from GitHub releases
    #>
    param(
        [hashtable]$ReleaseInfo,
        [System.Windows.Controls.ProgressBar]$ProgressBar = $null,
        [System.Windows.Controls.TextBlock]$StatusText = $null
    )
    
    $script:IsDownloading = $true
    
    try {
        $modId = $ReleaseInfo.ModId
        $downloadUrl = $ReleaseInfo.DownloadUrl
        $tempZipPath = Join-Path $env:TEMP "$modId-$($ReleaseInfo.Version).zip"
        $modTargetPath = Join-Path $script:ModsDirectory $modId
        
        Write-Host "Downloading $modId v$($ReleaseInfo.Version)..." -ForegroundColor Cyan
        
        if ($StatusText) {
            $StatusText.Dispatcher.Invoke([Action]{
                $StatusText.Text = "Downloading $modId..."
            })
        }
        
        if ($ProgressBar) {
            $ProgressBar.Dispatcher.Invoke([Action]{
                $ProgressBar.IsIndeterminate = $false
                $ProgressBar.Value = 0
                $ProgressBar.Visibility = "Visible"
            })
        }
        
        # Download with progress using WebClient
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "TNI-ModManager/3.0")
        
        # Simple synchronous download with progress callback
        $totalBytes = 0
        $downloadedBytes = 0
        
        # First, get the file size
        try {
            $request = [System.Net.WebRequest]::Create($downloadUrl)
            $request.Method = "HEAD"
            $request.UserAgent = "TNI-ModManager/3.0"
            $response = $request.GetResponse()
            $totalBytes = $response.ContentLength
            $response.Close()
        }
        catch {
            Write-Host "  Could not determine file size, continuing anyway..." -ForegroundColor Yellow
        }
        
        # Download with progress tracking
        $stream = $webClient.OpenRead($downloadUrl)
        $fileStream = [System.IO.File]::Create($tempZipPath)
        $buffer = New-Object byte[] 8192
        $lastProgress = 0
        
        while (($read = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $fileStream.Write($buffer, 0, $read)
            $downloadedBytes += $read
            
            if ($totalBytes -gt 0 -and $ProgressBar) {
                $progress = [int](($downloadedBytes / $totalBytes) * 100)
                if ($progress -ne $lastProgress) {
                    $lastProgress = $progress
                    $ProgressBar.Dispatcher.Invoke([Action]{
                        $ProgressBar.Value = $progress
                    })
                }
            }
            
            # Allow UI to update
            [System.Windows.Forms.Application]::DoEvents()
        }
        
        $stream.Close()
        $fileStream.Close()
        $webClient.Dispose()
        
        if ($StatusText) {
            $StatusText.Dispatcher.Invoke([Action]{
                $StatusText.Text = "Extracting $modId..."
            })
        }
        
        if ($ProgressBar) {
            $ProgressBar.Dispatcher.Invoke([Action]{
                $ProgressBar.IsIndeterminate = $true
            })
        }
        
        # Remove existing mod folder if exists
        if (Test-Path $modTargetPath) {
            Remove-Item $modTargetPath -Recurse -Force
        }
        
        # Create mods directory if needed
        if (-not (Test-Path $script:ModsDirectory)) {
            New-Item -Path $script:ModsDirectory -ItemType Directory -Force | Out-Null
        }
        
        # Extract zip
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($tempZipPath, $modTargetPath)
        
        # Clean up temp file
        Remove-Item $tempZipPath -Force -ErrorAction SilentlyContinue
        
        # Update mod cache to track this as a downloaded mod
        $script:ModCache[$modId] = @{
            Source = $script:ModSourceType.Downloaded
            Version = $ReleaseInfo.Version
            InstalledAt = (Get-Date).ToString("o")
        }
        Save-ModCache
        
        if ($StatusText) {
            $StatusText.Dispatcher.Invoke([Action]{
                $StatusText.Text = "$modId installed successfully!"
            })
        }
        
        if ($ProgressBar) {
            $ProgressBar.Dispatcher.Invoke([Action]{
                $ProgressBar.Visibility = "Collapsed"
            })
        }
        
        Write-Host "  [OK] Installed $modId v$($ReleaseInfo.Version)" -ForegroundColor Green
        return $true
        
    }
    catch {
        Write-Host "[ERROR] Download failed: $_" -ForegroundColor Red
        
        if ($StatusText) {
            $StatusText.Dispatcher.Invoke([Action]{
                $StatusText.Text = "Download failed: $_"
            })
        }
        
        if ($ProgressBar) {
            $ProgressBar.Dispatcher.Invoke([Action]{
                $ProgressBar.Visibility = "Collapsed"
            })
        }
        
        return $false
    }
    finally {
        $script:IsDownloading = $false
    }
}

function Remove-DownloadedMod {
    <#
    .SYNOPSIS
        Completely removes a downloaded mod from the filesystem
    #>
    param([string]$ModId)
    
    try {
        $modPath = Join-Path $script:ModsDirectory $ModId
        
        if (Test-Path $modPath) {
            Remove-Item $modPath -Recurse -Force
            Write-Host "  [OK] Removed downloaded mod: $ModId" -ForegroundColor Green
        }
        
        # Remove from cache
        if ($script:ModCache.ContainsKey($ModId)) {
            $script:ModCache.Remove($ModId)
            Save-ModCache
        }
        
        return $true
    }
    catch {
        Write-Host "[ERROR] Failed to remove mod: $_" -ForegroundColor Red
        return $false
    }
}

#endregion

#region Cache Management

function Load-ModCache {
    <#
    .SYNOPSIS
        Loads the mod cache that tracks downloaded vs manual mods
    #>
    if (Test-Path $script:ModCachePath) {
        try {
            $content = Get-Content $script:ModCachePath -Raw -Encoding UTF8
            $jsonObj = $content | ConvertFrom-Json
            
            # Convert PSObject to hashtable
            $script:ModCache = @{}
            foreach ($prop in $jsonObj.PSObject.Properties) {
                $script:ModCache[$prop.Name] = @{
                    Source = $prop.Value.Source
                    Version = $prop.Value.Version
                    InstalledAt = $prop.Value.InstalledAt
                }
            }
            
            Write-Host "  Loaded mod cache with $($script:ModCache.Count) entries" -ForegroundColor Gray
        }
        catch {
            Write-Host "[WARN] Failed to load mod cache: $_" -ForegroundColor Yellow
            $script:ModCache = @{}
        }
    }
    else {
        $script:ModCache = @{}
    }
}

function Save-ModCache {
    <#
    .SYNOPSIS
        Saves the mod cache to disk
    #>
    try {
        $cacheDir = Split-Path $script:ModCachePath -Parent
        if (-not (Test-Path $cacheDir)) {
            New-Item -Path $cacheDir -ItemType Directory -Force | Out-Null
        }
        
        $json = $script:ModCache | ConvertTo-Json -Depth 10
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($script:ModCachePath, $json, $utf8NoBom)
    }
    catch {
        Write-Host "[WARN] Failed to save mod cache: $_" -ForegroundColor Yellow
    }
}

#endregion

#region Helper Functions

function Convert-MarkdownToTextBlock {
    <#
    .SYNOPSIS
        Converts basic markdown (bold and links) to WPF TextBlock with Inlines
    #>
    param(
        [string]$Text,
        [System.Windows.Controls.TextBlock]$TextBlock
    )
    
    if ([string]::IsNullOrWhiteSpace($Text)) {
        return
    }
    
    $TextBlock.Inlines.Clear()
    $TextBlock.TextWrapping = "Wrap"
    
    # Split by markdown patterns
    $pattern = '(\*\*.*?\*\*|\[.*?\]\(.*?\))'
    $parts = [regex]::Split($Text, $pattern)
    
    foreach ($part in $parts) {
        if ([string]::IsNullOrEmpty($part)) { continue }
        
        # Handle bold: **text**
        if ($part -match '^\*\*(.*?)\*\*$') {
            $run = New-Object System.Windows.Documents.Run
            $run.Text = $Matches[1]
            $run.FontWeight = "Bold"
            $TextBlock.Inlines.Add($run)
        }
        # Handle links: [text](url)
        elseif ($part -match '^\[(.*?)\]\((.*?)\)$') {
            $linkText = $Matches[1]
            $linkUrl = $Matches[2]
            
            $hyperlink = New-Object System.Windows.Documents.Hyperlink
            $hyperlink.NavigateUri = $linkUrl
            $run = New-Object System.Windows.Documents.Run
            $run.Text = $linkText
            $hyperlink.Inlines.Add($run)
            $hyperlink.Foreground = "#FF0078D4"
            $hyperlink.Add_RequestNavigate({
                param($sender, $e)
                Start-Process $e.Uri.AbsoluteUri
                $e.Handled = $true
            })
            $TextBlock.Inlines.Add($hyperlink)
        }
        # Plain text
        else {
            $run = New-Object System.Windows.Documents.Run
            $run.Text = $part
            $TextBlock.Inlines.Add($run)
        }
    }
}

function Get-ModStatusColor {
    param(
        [string]$Status,
        [bool]$Enabled
    )
    
    $colors = @{
        'Active'       = @{ Enabled = '#FF4CAF50'; Disabled = '#FF2E7D32' }
        'Maintenance'  = @{ Enabled = '#FFFFD54F'; Disabled = '#FFF9A825' }
        'Discontinued' = @{ Enabled = '#FFFF9800'; Disabled = '#FFE65100' }
        'Unsupported'  = @{ Enabled = '#FFF44336'; Disabled = '#FFC62828' }
        'Defunct'      = @{ Enabled = '#FFF44336'; Disabled = '#FFC62828' }
    }
    
    if ($colors.ContainsKey($Status)) {
        if ($Enabled) {
            return $colors[$Status]['Enabled']
        }
        else {
            return $colors[$Status]['Disabled']
        }
    }
    
    if ($Enabled) {
        return '#FF808080'
    }
    else {
        return '#FF505050'
    }
}

function Get-ModSourceColor {
    param([string]$Source)
    
    switch ($Source) {
        "Downloaded" { return "#FF0078D4" }  # Blue
        "Manual" { return "#FF9C27B0" }      # Purple
        "Available" { return "#FF607D8B" }   # Gray
        default { return "#FF808080" }
    }
}

function Get-ModSourceIcon {
    param([string]$Source)
    
    switch ($Source) {
        "Downloaded" { return [char]0x2601 }  # Cloud
        "Manual" { return [char]0x1F4C1 }     # Folder
        "Available" { return [char]0x2B07 }   # Down arrow
        default { return "?" }
    }
}

#endregion

#region XAML UI Definition

$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="The Network Inc - Mod Manager v3.5.3" 
        Height="800" Width="1100" 
        WindowStartupLocation="CenterScreen"
        Background="#FF37474F">
    <Window.Resources>
        <Style TargetType="Button" x:Key="DefaultButton">
            <Setter Property="Background" Value="#FF0078D4"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="10,5"/>
            <Setter Property="Margin" Value="5"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#FF106EBE"/>
                </Trigger>
                <Trigger Property="IsEnabled" Value="False">
                    <Setter Property="Background" Value="#FF808080"/>
                    <Setter Property="Foreground" Value="#FFCCCCCC"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        <Style TargetType="Button" BasedOn="{StaticResource DefaultButton}"/>
        <Style TargetType="Button" x:Key="GreenButton">
            <Setter Property="Background" Value="#FF107C10"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="10,5"/>
            <Setter Property="Margin" Value="5"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#FF0E6A0E"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        <Style TargetType="Button" x:Key="RedButton">
            <Setter Property="Background" Value="#FFD13438"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="10,5"/>
            <Setter Property="Margin" Value="5"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#FFC62828"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        <Style TargetType="Button" x:Key="OrangeButton">
            <Setter Property="Background" Value="#FFFF9800"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="10,5"/>
            <Setter Property="Margin" Value="5"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#FFE65100"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Padding" Value="5"/>
            <Setter Property="FontSize" Value="12"/>
        </Style>
        <Style TargetType="CheckBox">
            <Setter Property="FontSize" Value="12"/>
        </Style>
        <Style TargetType="ComboBox">
            <Setter Property="FontSize" Value="12"/>
        </Style>
        <Style TargetType="Label">
            <Setter Property="FontSize" Value="12"/>
        </Style>
        <Style TargetType="TextBlock">
            <Setter Property="FontSize" Value="12"/>
        </Style>
    </Window.Resources>
    
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <!-- Header -->
        <StackPanel Grid.Row="0" Margin="0,0,0,10">
            <TextBlock Text="THE NETWORK INC - MOD MANAGER" 
                       FontSize="24" 
                       FontWeight="Bold" 
                       Foreground="#FF0078D4"
                       HorizontalAlignment="Center"
                       Margin="0,0,0,5"/>
            <TextBlock Name="StatusText" 
                       Text="Loading..." 
                       FontSize="11" 
                       Foreground="#FFAAAAAA"
                       HorizontalAlignment="Center"/>
        </StackPanel>
        
        <!-- Progress Bar -->
        <StackPanel Grid.Row="1" Margin="0,0,0,10">
            <ProgressBar Name="DownloadProgressBar" 
                         Height="20" 
                         Minimum="0" 
                         Maximum="100"
                         Visibility="Collapsed"/>
            <TextBlock Name="DownloadStatusText"
                       FontSize="10"
                       Foreground="#FFAAAAAA"
                       HorizontalAlignment="Center"
                       Margin="0,5,0,0"/>
        </StackPanel>
        
        <!-- Main Content -->
        <TabControl Grid.Row="2" Background="Transparent" BorderThickness="0">
            <!-- Mods Tab -->
            <TabItem Header="Mods" FontSize="13">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="350"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
            
                    <!-- Mod List Panel -->
                    <Border Grid.Column="0" 
                            Background="White"
                            BorderThickness="1"
                            Margin="0,0,5,0">
                        <Grid>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                                <RowDefinition Height="Auto"/>
                            </Grid.RowDefinitions>
                            
                            <StackPanel Grid.Row="0" Margin="10,10,10,5">
                                <TextBlock Text="Mods" 
                                           FontSize="16" 
                                           FontWeight="Bold"/>
                                <StackPanel Orientation="Horizontal" Margin="0,5,0,0">
                                    <Border Background="#FF0078D4" CornerRadius="2" Padding="4,1" Margin="0,0,8,0">
                                        <TextBlock Text="Downloaded" FontSize="9" Foreground="White"/>
                                    </Border>
                                    <Border Background="#FF9C27B0" CornerRadius="2" Padding="4,1" Margin="0,0,8,0">
                                        <TextBlock Text="Manual" FontSize="9" Foreground="White"/>
                                    </Border>
                                    <Border Background="#FF607D8B" CornerRadius="2" Padding="4,1">
                                        <TextBlock Text="Available" FontSize="9" Foreground="White"/>
                                    </Border>
                                </StackPanel>
                            </StackPanel>
                            
                            <!-- Filter Tabs -->
                            <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="10,0,10,5">
                                <RadioButton Name="FilterAll" Content="All" IsChecked="True" Margin="0,0,10,0"/>
                                <RadioButton Name="FilterInstalled" Content="Installed" Margin="0,0,10,0"/>
                                <RadioButton Name="FilterAvailable" Content="Available" Margin="0,0,10,0"/>
                            </StackPanel>
                            
                            <ListBox Name="ModListBox" 
                                     Grid.Row="2"
                                     BorderThickness="0"
                                     Margin="5"
                                     ScrollViewer.HorizontalScrollBarVisibility="Disabled"/>
                            
                            <StackPanel Grid.Row="3" Margin="5">
                                <Button Name="LaunchGameButton" Content="Launch Game" Style="{StaticResource GreenButton}" FontWeight="Bold"/>
                                <Button Name="RefreshButton" Content="Refresh Mods"/>
                            </StackPanel>
                        </Grid>
                    </Border>
                    
                    <!-- Details Panel -->
                    <Border Grid.Column="1" 
                            Background="White"
                            BorderThickness="1"
                            Margin="5,0,0,0">
                        <ScrollViewer VerticalScrollBarVisibility="Auto" 
                                      HorizontalScrollBarVisibility="Disabled">
                            <Grid Name="DetailsPanel" Margin="15">
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="Auto"/>
                                </Grid.RowDefinitions>
                            
                                <!-- Empty State -->
                                <StackPanel Grid.Row="0" 
                                            Name="EmptyStatePanel"
                                            VerticalAlignment="Center"
                                            HorizontalAlignment="Center"
                                            Margin="0,100,0,0">
                                    <TextBlock Text="Select a mod to view details" 
                                               FontSize="16"
                                               Foreground="#FF808080"
                                               HorizontalAlignment="Center"/>
                                    <TextBlock Text="or download available mods from the list" 
                                               FontSize="12"
                                               Foreground="#FFAAAAAA"
                                               HorizontalAlignment="Center"
                                               Margin="0,5,0,0"/>
                                </StackPanel>
                            
                                <!-- Mod Info -->
                                <StackPanel Grid.Row="0" Name="ModInfoPanel" Visibility="Collapsed">
                                    <Grid>
                                        <Grid.ColumnDefinitions>
                                            <ColumnDefinition Width="*"/>
                                            <ColumnDefinition Width="Auto"/>
                                        </Grid.ColumnDefinitions>
                                        
                                        <StackPanel Grid.Column="0">
                                            <TextBlock Name="ModNameText" 
                                                       FontSize="20" 
                                                       FontWeight="Bold"
                                                       TextWrapping="Wrap"
                                                       Margin="0,0,0,5"/>
                                            <StackPanel Orientation="Horizontal">
                                                <Border Name="ModSourceBadge" 
                                                        Background="#FF0078D4" 
                                                        CornerRadius="3" 
                                                        Padding="8,3"
                                                        Margin="0,0,10,0">
                                                    <TextBlock Name="ModSourceText" 
                                                               Text="Downloaded" 
                                                               Foreground="White" 
                                                               FontSize="10"
                                                               FontWeight="Bold"/>
                                                </Border>
                                                <Border Name="ModVersionBadge" 
                                                        Background="#FF808080" 
                                                        CornerRadius="3" 
                                                        Padding="8,3">
                                                    <TextBlock Name="ModVersionBadgeText" 
                                                               Text="v0.1.0" 
                                                               Foreground="White" 
                                                               FontSize="10"/>
                                                </Border>
                                            </StackPanel>
                                        </StackPanel>
                                        
                                        <!-- Action Buttons -->
                                        <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Top">
                                            <Button Name="DownloadButton" Content="Download" Style="{StaticResource GreenButton}" Visibility="Collapsed"/>
                                            <Button Name="UpdateButton" Content="Update Available" Style="{StaticResource OrangeButton}" Visibility="Collapsed"/>
                                            <Button Name="RemoveButton" Content="Remove" Style="{StaticResource RedButton}" Visibility="Collapsed"/>
                                            <Button Name="DisableButton" Content="Disable" Visibility="Collapsed"/>
                                            <Button Name="EnableButton" Content="Enable" Style="{StaticResource GreenButton}" Visibility="Collapsed"/>
                                        </StackPanel>
                                    </Grid>
                                    
                                    <Grid Margin="0,15,0,0">
                                        <Grid.ColumnDefinitions>
                                            <ColumnDefinition Width="Auto"/>
                                            <ColumnDefinition Width="*"/>
                                        </Grid.ColumnDefinitions>
                                        <Grid.RowDefinitions>
                                            <RowDefinition Height="Auto"/>
                                            <RowDefinition Height="Auto"/>
                                            <RowDefinition Height="Auto"/>
                                            <RowDefinition Height="Auto"/>
                                            <RowDefinition Height="Auto"/>
                                        </Grid.RowDefinitions>
                                        
                                        <TextBlock Grid.Row="0" Grid.Column="0" Text="Author: " FontWeight="Bold" Margin="0,2"/>
                                        <TextBlock Grid.Row="0" Grid.Column="1" Name="ModAuthorText" Margin="5,2"/>
                                        
                                        <TextBlock Grid.Row="1" Grid.Column="0" Text="Status: " FontWeight="Bold" Margin="0,2"/>
                                        <TextBlock Grid.Row="1" Grid.Column="1" Name="ModStatusText" Margin="5,2"/>
                                        
                                        <TextBlock Grid.Row="2" Grid.Column="0" Text="Version: " FontWeight="Bold" Margin="0,2"/>
                                        <TextBlock Grid.Row="2" Grid.Column="1" Name="ModVersionText" Margin="5,2"/>
                                        
                                        <TextBlock Grid.Row="3" Grid.Column="0" Text="Game: " FontWeight="Bold" Margin="0,2"/>
                                        <TextBlock Grid.Row="3" Grid.Column="1" Name="ModGameVersionText" Margin="5,2"/>
                                        
                                        <TextBlock Grid.Row="4" Grid.Column="0" Text="Updated: " FontWeight="Bold" Margin="0,2"/>
                                        <TextBlock Grid.Row="4" Grid.Column="1" Name="ModLastUpdatedText" Margin="5,2"/>
                                    </Grid>
                                </StackPanel>
                                
                                <!-- Description -->
                                <Expander Grid.Row="1" 
                                          Name="DescriptionExpander"
                                          Header="Description" 
                                          IsExpanded="True"
                                          Visibility="Collapsed"
                                          Margin="0,15,0,0">
                                    <Border Name="ModDescriptionBorder" 
                                            Padding="10"
                                            Background="#FFF8F8F8"
                                            MaxHeight="200">
                                        <ScrollViewer VerticalScrollBarVisibility="Auto">
                                            <TextBlock Name="ModDescriptionText" TextWrapping="Wrap"/>
                                        </ScrollViewer>
                                    </Border>
                                </Expander>
                                
                                <!-- Update Available Notice -->
                                <Border Grid.Row="2" 
                                        Name="UpdateNoticePanel"
                                        Background="#FFFFF3CD" 
                                        BorderBrush="#FFFFC107" 
                                        BorderThickness="1"
                                        Padding="10"
                                        Margin="0,15,0,0"
                                        Visibility="Collapsed">
                                    <StackPanel>
                                        <TextBlock FontWeight="Bold" Foreground="#FF856404">
                                            <Run Text="Update Available: "/>
                                            <Run Name="UpdateVersionText" Text="v0.2.0"/>
                                        </TextBlock>
                                        <TextBlock Name="UpdateNotesText" 
                                                   TextWrapping="Wrap" 
                                                   Margin="0,5,0,0"
                                                   Foreground="#FF856404"
                                                   FontSize="11"/>
                                    </StackPanel>
                                </Border>
                                
                                <!-- Parameters -->
                                <StackPanel Grid.Row="3" Name="ParametersPanel" Visibility="Collapsed" Margin="0,15,0,0">
                                    <TextBlock Text="Configuration Parameters" 
                                               FontSize="14" 
                                               FontWeight="Bold"
                                               Margin="0,0,0,10"/>
                                    <StackPanel Name="ParametersList"/>
                                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,10,0,0">
                                        <Button Name="ResetModButton" Content="Reset Defaults" Width="120"/>
                                        <Button Name="SaveButton" Content="Save Changes" Style="{StaticResource GreenButton}" Width="120"/>
                                    </StackPanel>
                                </StackPanel>
                            </Grid>
                        </ScrollViewer>
                    </Border>
                </Grid>
            </TabItem>
            
            <!-- Aliases Tab -->
            <TabItem Header="Command Aliases" FontSize="13">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="300"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    
                    <!-- Alias List Panel -->
                    <Border Grid.Column="0" 
                            Background="White"
                            BorderThickness="1"
                            Margin="0,0,5,0">
                        <Grid>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                                <RowDefinition Height="Auto"/>
                            </Grid.RowDefinitions>
                            
                            <TextBlock Grid.Row="0" 
                                       Text="Command Aliases" 
                                       FontSize="14" 
                                       FontWeight="Bold"
                                       Margin="10,10,10,5"/>
                            
                            <ListBox Name="AliasListBox" 
                                     Grid.Row="1"
                                     BorderThickness="0"
                                     Margin="5"
                                     ScrollViewer.HorizontalScrollBarVisibility="Disabled"/>
                            
                            <StackPanel Grid.Row="2" Margin="5">
                                <Button Name="AddAliasButton" Content="+ New Alias" Style="{StaticResource GreenButton}"/>
                                <Button Name="DeleteAliasButton" Content="Delete Alias" Style="{StaticResource RedButton}"/>
                                <Button Name="SaveAliasesButton" Content="Save Aliases"/>
                            </StackPanel>
                        </Grid>
                    </Border>
                    
                    <!-- Alias Details Panel -->
                    <Border Grid.Column="1" 
                            Background="White"
                            BorderThickness="1"
                            Margin="5,0,0,0">
                        <ScrollViewer VerticalScrollBarVisibility="Auto" 
                                      HorizontalScrollBarVisibility="Disabled">
                            <Grid Name="AliasDetailsPanel" Margin="10">
                                <!-- Empty State -->
                                <StackPanel Name="AliasEmptyState"
                                            VerticalAlignment="Center"
                                            HorizontalAlignment="Center">
                                    <TextBlock Text="Select an alias or create a new one" 
                                               FontSize="16"
                                               Foreground="#FF808080"
                                               HorizontalAlignment="Center"/>
                                </StackPanel>
                                
                                <!-- Alias Editor -->
                                <StackPanel Name="AliasEditorPanel" Visibility="Collapsed">
                                    <TextBlock Text="Alias Editor" 
                                               FontSize="18" 
                                               FontWeight="Bold"
                                               Margin="0,0,0,20"/>
                                    
                                    <TextBlock Text="Alias Name:" FontWeight="Bold" Margin="0,0,0,5"/>
                                    <TextBox Name="AliasNameBox" 
                                             Margin="0,0,0,15"
                                             Padding="5"
                                             FontFamily="Consolas"/>
                                    
                                    <TextBlock Text="Command:" FontWeight="Bold" Margin="0,0,0,5"/>
                                    <TextBox Name="AliasCommandBox" 
                                             TextWrapping="Wrap"
                                             AcceptsReturn="True"
                                             MinHeight="100"
                                             Margin="0,0,0,15"
                                             Padding="5"
                                             FontFamily="Consolas"
                                             VerticalScrollBarVisibility="Auto"/>
                                    
                                    <TextBlock Text="Preview:" FontWeight="Bold" Margin="0,0,0,5"/>
                                    <Border Background="#FFF5F5F5" 
                                            BorderBrush="#FFCCCCCC" 
                                            BorderThickness="1"
                                            Padding="10"
                                            Margin="0,0,0,15">
                                        <TextBlock Name="AliasPreviewText" 
                                                   TextWrapping="Wrap"
                                                   FontFamily="Consolas"
                                                   FontSize="11"
                                                   Foreground="#FF666666"/>
                                    </Border>
                                    
                                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                                        <Button Name="CancelAliasButton" Content="Cancel" Width="100"/>
                                        <Button Name="ApplyAliasButton" Content="Apply" Style="{StaticResource GreenButton}" Width="100"/>
                                    </StackPanel>
                                </StackPanel>
                            </Grid>
                        </ScrollViewer>
                    </Border>
                </Grid>
            </TabItem>
        </TabControl>
        
        <!-- Footer -->
        <StackPanel Grid.Row="3" Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,10,0,0">
            <Button Name="SaveAllButton" Content="Save All Changes" Width="150" Height="30"/>
            <Button Name="ExitButton" Content="Exit" Width="100" Height="30"/>
        </StackPanel>
    </Grid>
</Window>
"@

#endregion

#region YAML Parser

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
    $paramMultilineKey = $null
    $paramMultilineValue = @()
    $inParamMultiline = $false
    
    foreach ($line in $lines) {
        if ([string]::IsNullOrWhiteSpace($line) -or $line.Trim().StartsWith('#')) {
            continue
        }
        
        if ($line -match '^(\w+(?:\s+\w+)*):\s*\|') {
            $currentKey = $Matches[1]
            $inMultiline = $true
            $multilineValue = @()
            continue
        }
        
        if ($inMultiline) {
            if ($line -match '^\s{2,}(.+)') {
                $multilineValue += $Matches[1]
            }
            else {
                $result[$currentKey] = $multilineValue -join "`n"
                $inMultiline = $false
                $currentKey = $null
            }
        }
        
        if ($line -match '^Parameters:\s*$') {
            $inParameters = $true
            continue
        }
        
        if ($inParameters -and $line -match '^\s{2}-\s+Name:\s*(.+)') {
            if ($currentParam) {
                if ($inParamMultiline -and $paramMultilineKey) {
                    $currentParam[$paramMultilineKey] = $paramMultilineValue -join "`n"
                }
                $parameters += $currentParam
            }
            $currentParam = @{ Name = $Matches[1].Trim() }
            $inParamMultiline = $false
            continue
        }
        
        if ($inParameters -and $currentParam -and $line -match '^\s{4}(\w+):\s*\|') {
            if ($inParamMultiline -and $paramMultilineKey) {
                $currentParam[$paramMultilineKey] = $paramMultilineValue -join "`n"
            }
            $paramMultilineKey = $Matches[1]
            $inParamMultiline = $true
            $paramMultilineValue = @()
            continue
        }
        
        if ($inParamMultiline -and $line -match '^\s{6,}(.+)') {
            $paramMultilineValue += $Matches[1]
            continue
        }
        
        if ($inParamMultiline -and $line -match '^\s{4}(\w+):\s*(.*)') {
            $currentParam[$paramMultilineKey] = $paramMultilineValue -join "`n"
            $inParamMultiline = $false
            $paramMultilineKey = $null
            
            $paramKey = $Matches[1]
            $paramValue = $Matches[2].Trim()
            
            if ($paramValue -match '^"(.*)"$') {
                $paramValue = $Matches[1]
            }
            
            if ($paramValue -eq 'true') { $paramValue = $true }
            elseif ($paramValue -eq 'false') { $paramValue = $false }
            elseif ($paramValue -match '^\d+$') { $paramValue = [int]$paramValue }
            elseif ($paramValue -match '^\d+\.\d+$') { $paramValue = [double]$paramValue }
            elseif ($paramValue -match '^\[(.*)\]$') {
                $paramValue = $Matches[1] -split ',\s*' | ForEach-Object { 
                    $_.Trim().Trim('"') 
                }
            }
            
            $currentParam[$paramKey] = $paramValue
            continue
        }
        
        if ($inParameters -and $currentParam -and $line -match '^\s{4}(\w+):\s*(.*)') {
            $paramKey = $Matches[1]
            $paramValue = $Matches[2].Trim()
            
            if ($paramValue -match '^"(.*)"$') {
                $paramValue = $Matches[1]
            }
            
            if ($paramValue -eq 'true') { $paramValue = $true }
            elseif ($paramValue -eq 'false') { $paramValue = $false }
            elseif ($paramValue -match '^\d+$') { $paramValue = [int]$paramValue }
            elseif ($paramValue -match '^\d+\.\d+$') { $paramValue = [double]$paramValue }
            elseif ($paramValue -match '^\[(.*)\]$') {
                $paramValue = $Matches[1] -split ',\s*' | ForEach-Object { 
                    $_.Trim().Trim('"') 
                }
            }
            
            $currentParam[$paramKey] = $paramValue
            continue
        }
        
        if ($line -match '^(\w+(?:\s+\w+)*):\s*(.*)') {
            $key = $Matches[1]
            $value = $Matches[2].Trim()
            
            if ($value -match '^"(.*)"$') {
                $value = $Matches[1]
            }
            
            if ($value -eq 'true') { $value = $true }
            elseif ($value -eq 'false') { $value = $false }
            elseif ($value -match '^\d+$') { $value = [int]$value }
            elseif ($value -match '^\d+\.\d+$') { $value = [double]$value }
            elseif ($value -eq '[]' -or $value -eq '') { $value = @() }
            
            $result[$key] = $value
        }
    }
    
    if ($currentParam) {
        if ($inParamMultiline -and $paramMultilineKey) {
            $currentParam[$paramMultilineKey] = $paramMultilineValue -join "`n"
        }
        $parameters += $currentParam
    }
    
    if ($inMultiline -and $currentKey) {
        $result[$currentKey] = $multilineValue -join "`n"
    }
    
    if ($parameters.Count -gt 0) {
        $result['Parameters'] = $parameters
    }
    
    return $result
}

#endregion

#region Mod Discovery

function Get-InstalledMods {
    <#
    .SYNOPSIS
        Scans for installed mods (both in Mods and Mods_Disabled directories)
    #>
    Write-Host "Scanning for installed mods..." -ForegroundColor Cyan
    $mods = @()
    
    # Scan enabled mods
    if (Test-Path $script:ModsDirectory) {
        $modFolders = Get-ChildItem -Path $script:ModsDirectory -Directory | 
            Where-Object { $_.Name -ne '.lua-typing' }
        
        foreach ($folder in $modFolders) {
            $metadataPath = Join-Path $folder.FullName "metadata.yaml"
            
            if (Test-Path $metadataPath) {
                try {
                    $content = Get-Content $metadataPath -Raw -Encoding UTF8
                    $metadata = ConvertFrom-SimpleYaml $content
                    $metadata['Folder'] = $folder.Name
                    $metadata['Enabled'] = $true
                    
                    # Determine source type from cache
                    if ($script:ModCache.ContainsKey($metadata['ID'])) {
                        $metadata['Source'] = $script:ModCache[$metadata['ID']].Source
                        $metadata['InstalledVersion'] = $script:ModCache[$metadata['ID']].Version
                    }
                    else {
                        $metadata['Source'] = $script:ModSourceType.Manual
                        $metadata['InstalledVersion'] = $metadata['Version']
                    }
                    
                    $mods += $metadata
                    Write-Host "  [OK] $($metadata['Name']) ($($metadata['Source']))" -ForegroundColor Green
                }
                catch {
                    Write-Host "  [WARN] Failed to parse: $($folder.Name)" -ForegroundColor Yellow
                }
            }
        }
    }
    
    # Scan disabled mods (manual only)
    if (Test-Path $script:DisabledModsDirectory) {
        $disabledFolders = Get-ChildItem -Path $script:DisabledModsDirectory -Directory
        
        foreach ($folder in $disabledFolders) {
            $metadataPath = Join-Path $folder.FullName "metadata.yaml"
            
            if (Test-Path $metadataPath) {
                try {
                    $content = Get-Content $metadataPath -Raw -Encoding UTF8
                    $metadata = ConvertFrom-SimpleYaml $content
                    $metadata['Folder'] = $folder.Name
                    $metadata['Enabled'] = $false
                    $metadata['Source'] = $script:ModSourceType.Manual
                    $metadata['InstalledVersion'] = $metadata['Version']
                    
                    $mods += $metadata
                    Write-Host "  [OK] $($metadata['Name']) (Manual, Disabled)" -ForegroundColor Gray
                }
                catch {
                    Write-Host "  [WARN] Failed to parse disabled: $($folder.Name)" -ForegroundColor Yellow
                }
            }
        }
    }
    
    Write-Host "Found $($mods.Count) installed mod(s)" -ForegroundColor Green
    return $mods
}

function Get-AllMods {
    <#
    .SYNOPSIS
        Combines installed mods with available mods from GitHub releases
    #>
    param([hashtable]$GitHubReleases)
    
    $allMods = @()
    
    # Add installed mods
    foreach ($mod in $script:InstalledMods) {
        $modEntry = @{}
        foreach ($key in $mod.Keys) {
            $modEntry[$key] = $mod[$key]
        }
        
        # Check for updates
        if ($GitHubReleases.ContainsKey($mod['ID'])) {
            $release = $GitHubReleases[$mod['ID']]
            $modEntry['LatestVersion'] = $release.Version
            $modEntry['DownloadUrl'] = $release.DownloadUrl
            $modEntry['ReleaseInfo'] = $release
            
            if ($mod['InstalledVersion']) {
                $comparison = Compare-SemanticVersion $release.Version $mod['InstalledVersion']
                $modEntry['UpdateAvailable'] = ($comparison -gt 0)
            }
        }
        
        $allMods += $modEntry
    }
    
    # Add available (not installed) mods from GitHub
    foreach ($modId in $GitHubReleases.Keys) {
        $isInstalled = $script:InstalledMods | Where-Object { $_['ID'] -eq $modId }
        
        if (-not $isInstalled) {
            $release = $GitHubReleases[$modId]
            
            $modEntry = @{
                'ID' = $modId
                'Name' = ($modId -replace '-', ' ').ToUpper().Substring(0,1) + ($modId -replace '-', ' ').Substring(1)
                'Folder' = $modId
                'Enabled' = $false
                'Source' = $script:ModSourceType.Available
                'Version' = $release.Version
                'LatestVersion' = $release.Version
                'DownloadUrl' = $release.DownloadUrl
                'ReleaseInfo' = $release
                'Author' = 'Unknown'
                'Development Status' = 'Active Development'
                'Game Version Supported' = 'beta'
                'Description' = "Available for download. Published: $($release.PublishedAt)"
                'Last Updated' = $release.PublishedAt
            }
            
            $allMods += $modEntry
        }
    }
    
    return $allMods
}

#endregion

#region Mod Configuration

function Get-ModParameters {
    param(
        [hashtable]$Mod,
        [hashtable]$CurrentConfig = @{}
    )
    
    if (-not $Mod) { return @() }
    
    $modFolder = $Mod['Folder']
    $modPath = Join-Path $script:ModsDirectory $modFolder
    
    # Check for ui-config.ps1 first
    $uiConfigPath = Join-Path $modPath "ui-config.ps1"
    
    if (Test-Path $uiConfigPath) {
        Write-Host "  Loading UI config from ui-config.ps1..." -ForegroundColor Gray
        try {
            # Read and execute script content to bypass execution policy in compiled exe
            $scriptContent = Get-Content $uiConfigPath -Raw
            $scriptBlock = [ScriptBlock]::Create($scriptContent)
            $parameters = & $scriptBlock -CurrentConfig $CurrentConfig
            
            if ($parameters -and $parameters.Count -gt 0) {
                return $parameters
            }
        }
        catch {
            Write-Host "  [WARN] ui-config.ps1 failed: $_" -ForegroundColor Yellow
        }
    }
    
    # Fall back to metadata.yaml Parameters
    if ($Mod.ContainsKey('Parameters') -and $Mod['Parameters'].Count -gt 0) {
        return $Mod['Parameters']
    }
    
    return @()
}

function Get-ModConfig {
    param($ModId)
    
    $entryPath = Join-Path $script:ModsDirectory "$ModId\entry.lua"
    
    if (-not (Test-Path $entryPath)) {
        return @{}
    }
    
    try {
        $config = @{}
        $content = Get-Content $entryPath -Raw
        
        if ($content -match '(?s)-- ===== MOD CONFIGURATION START =====.*?local config = \{(.*?)\}.*?-- ===== MOD CONFIGURATION END =====') {
            $configBlock = $Matches[1]
            
            foreach ($line in ($configBlock -split "`n")) {
                $line = $line.Trim()
                
                if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('--')) {
                    continue
                }
                
                if ($line -match '^\s*(\w+)\s*=\s*(.+?),?\s*(--.*)?$') {
                    $key = $Matches[1]
                    $value = $Matches[2].TrimEnd(',').Trim()
                    $value = $value -replace '\s*--.*$', ''
                    $value = $value.Trim().TrimEnd(',')
                    
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
        Write-Host "  [WARN] Failed to parse config: $_" -ForegroundColor Yellow
        return @{}
    }
}

function Save-ModConfig {
    param($ModId, $Config)
    
    try {
        $entryPath = Join-Path $script:ModsDirectory "$ModId\entry.lua"
        
        if (-not (Test-Path $entryPath)) {
            Write-Host "  [WARN] entry.lua not found for $ModId" -ForegroundColor Yellow
            return $false
        }
        
        $content = Get-Content $entryPath -Raw
        
        if ($content -match '(?s)(.*?-- ===== MOD CONFIGURATION START =====.*?local config = \{)(.*?)(\}.*?-- ===== MOD CONFIGURATION END =====.*)') {
            $prefix = $Matches[1]
            $suffix = $Matches[3]
            
            $newConfigLines = @()
            $sortedKeys = $Config.Keys | Sort-Object
            
            foreach ($key in $sortedKeys) {
                $value = $Config[$key]
                
                if ($value -is [bool]) {
                    $formattedValue = $value.ToString().ToLower()
                }
                elseif ($value -is [int] -or $value -is [long]) {
                    $formattedValue = $value.ToString()
                }
                elseif ($value -is [double] -or $value -is [float]) {
                    $formattedValue = $value.ToString('0.0#####')
                }
                else {
                    $formattedValue = "`"$value`""
                }
                
                $newConfigLines += "    $key = $formattedValue,"
            }
            
            $newConfigBlock = "`n" + ($newConfigLines -join "`n") + "`n"
            $newContent = $prefix + $newConfigBlock + $suffix
            
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($entryPath, $newContent, $utf8NoBom)
            
            return $true
        }
        else {
            Write-Host "  [WARN] Config section not found in $ModId" -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "  [ERROR] Save failed: $_" -ForegroundColor Red
        return $false
    }
}

#endregion

#region Settings Management

function Get-GameSettings {
    if (-not (Test-Path $script:SettingsPath)) {
        return $null
    }
    
    try {
        $content = Get-Content $script:SettingsPath -Raw -Encoding UTF8
        $settings = $content | ConvertFrom-Json
        
        if ($settings.cmd_alias) {
            $script:CmdAliases = @{}
            $settings.cmd_alias.PSObject.Properties | ForEach-Object {
                $script:CmdAliases[$_.Name] = $_.Value
            }
        }
        
        return $settings
    }
    catch {
        Write-Host "[WARN] Failed to load settings: $_" -ForegroundColor Yellow
        return $null
    }
}

function Save-GameSettings {
    param($Settings)
    
    try {
        if ($script:CmdAliases) {
            $aliasObj = New-Object PSObject
            foreach ($key in $script:CmdAliases.Keys) {
                $aliasObj | Add-Member -NotePropertyName $key -NotePropertyValue $script:CmdAliases[$key]
            }
            $Settings.cmd_alias = $aliasObj
        }
        
        $settingsDir = Split-Path $script:SettingsPath -Parent
        if (-not (Test-Path $settingsDir)) {
            New-Item -Path $settingsDir -ItemType Directory -Force | Out-Null
        }
        
        $json = $Settings | ConvertTo-Json -Depth 10
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($script:SettingsPath, $json, $utf8NoBom)
        
        return $true
    }
    catch {
        Write-Host "[ERROR] Failed to save settings: $_" -ForegroundColor Red
        return $false
    }
}

#endregion

#region Mod Enable/Disable

function Set-ModEnabled {
    param(
        [hashtable]$Mod,
        [bool]$Enabled
    )
    
    try {
        $modFolder = $Mod['Folder']
        $source = $Mod['Source']
        
        Write-Host "Set-ModEnabled: $modFolder, Enabled: $Enabled, Source: $source" -ForegroundColor Cyan
        
        if ($source -eq $script:ModSourceType.Downloaded) {
            # Downloaded mods: Remove completely when disabled
            if (-not $Enabled) {
                $result = Remove-DownloadedMod $modFolder
                return $result
            }
        }
        else {
            # Manual mods: Move between Mods and Mods_Disabled folders
            if (-not (Test-Path $script:ModsDirectory)) {
                New-Item -Path $script:ModsDirectory -ItemType Directory -Force | Out-Null
            }
            
            if (-not (Test-Path $script:DisabledModsDirectory)) {
                New-Item -Path $script:DisabledModsDirectory -ItemType Directory -Force | Out-Null
            }
            
            $enabledPath = Join-Path $script:ModsDirectory $modFolder
            $disabledPath = Join-Path $script:DisabledModsDirectory $modFolder
            
            if ($Enabled) {
                if (Test-Path $disabledPath) {
                    Move-Item -Path $disabledPath -Destination $enabledPath -Force
                    Write-Host "  [OK] Enabled: $modFolder" -ForegroundColor Green
                }
            }
            else {
                if (Test-Path $enabledPath) {
                    Move-Item -Path $enabledPath -Destination $disabledPath -Force
                    Write-Host "  [OK] Disabled: $modFolder" -ForegroundColor Green
                }
            }
        }
        
        return $true
    }
    catch {
        Write-Host "[ERROR] Set-ModEnabled failed: $_" -ForegroundColor Red
        return $false
    }
}

#endregion

#region UI Update Functions

function Update-ModList {
    param(
        $ListBox,
        [string]$Filter = "All"
    )
    
    try {
        Write-Host "Updating mod list (Filter: $Filter)..." -ForegroundColor Cyan
        $ListBox.Items.Clear()
        
        foreach ($mod in $script:AllMods) {
            # Apply filter
            $show = $false
            switch ($Filter) {
                "All" { $show = $true }
                "Installed" { $show = ($mod['Source'] -ne $script:ModSourceType.Available) }
                "Available" { $show = ($mod['Source'] -eq $script:ModSourceType.Available) }
            }
            
            if (-not $show) { continue }
            
            $item = New-ModListItem $mod
            $ListBox.Items.Add($item) | Out-Null
        }
        
        Write-Host "  Listed $($ListBox.Items.Count) mods" -ForegroundColor Green
    }
    catch {
        Write-Host "[ERROR] Update-ModList: $_" -ForegroundColor Red
    }
}

function New-ModListItem {
    param($mod)
    
    $source = $mod['Source']
    $enabled = $mod['Enabled']
    $updateAvailable = $mod['UpdateAvailable']
    
    $border = New-Object System.Windows.Controls.Border
    $border.Margin = "0,2"
    $border.Padding = "8"
    $border.BorderThickness = "3,0,0,0"
    
    # Color based on source and state
    $borderBrush = New-Object System.Windows.Media.SolidColorBrush
    $bgBrush = New-Object System.Windows.Media.SolidColorBrush
    
    if ($source -eq $script:ModSourceType.Available) {
        $borderBrush.Color = [System.Windows.Media.ColorConverter]::ConvertFromString("#FF607D8B")
        $bgBrush.Color = [System.Windows.Media.ColorConverter]::ConvertFromString("#FFF5F5F5")
    }
    elseif ($source -eq $script:ModSourceType.Downloaded) {
        $borderBrush.Color = [System.Windows.Media.ColorConverter]::ConvertFromString("#FF0078D4")
        if ($enabled) {
            $bgBrush.Color = [System.Windows.Media.ColorConverter]::ConvertFromString("#FFFFFFFF")
        }
        else {
            $bgBrush.Color = [System.Windows.Media.ColorConverter]::ConvertFromString("#FFEEEEEE")
        }
    }
    else {
        $borderBrush.Color = [System.Windows.Media.ColorConverter]::ConvertFromString("#FF9C27B0")
        if ($enabled) {
            $bgBrush.Color = [System.Windows.Media.ColorConverter]::ConvertFromString("#FFFFFFFF")
        }
        else {
            $bgBrush.Color = [System.Windows.Media.ColorConverter]::ConvertFromString("#FFEEEEEE")
        }
    }
    
    $border.BorderBrush = $borderBrush
    $border.Background = $bgBrush
    
    $grid = New-Object System.Windows.Controls.Grid
    $col1 = New-Object System.Windows.Controls.ColumnDefinition
    $col1.Width = "Auto"
    $col2 = New-Object System.Windows.Controls.ColumnDefinition
    $col2.Width = "*"
    $col3 = New-Object System.Windows.Controls.ColumnDefinition
    $col3.Width = "Auto"
    $grid.ColumnDefinitions.Add($col1)
    $grid.ColumnDefinitions.Add($col2)
    $grid.ColumnDefinitions.Add($col3)
    
    # Source indicator (colored box)
    $sourceBox = New-Object System.Windows.Controls.Border
    $sourceBox.Width = 6
    $sourceBox.Height = 20
    $sourceBox.CornerRadius = "2"
    $sourceBox.Margin = "0,0,8,0"
    $sourceBox.VerticalAlignment = "Center"
    $sourceBoxBrush = New-Object System.Windows.Media.SolidColorBrush
    $sourceBoxBrush.Color = [System.Windows.Media.ColorConverter]::ConvertFromString((Get-ModSourceColor $source))
    $sourceBox.Background = $sourceBoxBrush
    [System.Windows.Controls.Grid]::SetColumn($sourceBox, 0)
    $grid.Children.Add($sourceBox) | Out-Null
    
    # Mod info
    $stackPanel = New-Object System.Windows.Controls.StackPanel
    
    $nameText = New-Object System.Windows.Controls.TextBlock
    $nameText.Text = $mod['Name']
    $nameText.FontWeight = "Bold"
    $nameText.TextWrapping = "Wrap"
    if (-not $enabled -and $source -ne $script:ModSourceType.Available) {
        $nameText.Foreground = "#FF808080"
    }
    $stackPanel.Children.Add($nameText) | Out-Null
    
    $infoPanel = New-Object System.Windows.Controls.StackPanel
    $infoPanel.Orientation = "Horizontal"
    
    $versionText = New-Object System.Windows.Controls.TextBlock
    $version = if ($mod['InstalledVersion']) { $mod['InstalledVersion'] } else { $mod['Version'] }
    $versionText.Text = "v$version"
    $versionText.FontSize = 10
    $versionText.Foreground = "#FF808080"
    $versionText.Margin = "0,0,10,0"
    $infoPanel.Children.Add($versionText) | Out-Null
    
    if ($updateAvailable) {
        $updateBadge = New-Object System.Windows.Controls.TextBlock
        $updateBadge.Text = "UPDATE"
        $updateBadge.FontSize = 9
        $updateBadge.Foreground = "#FFFF9800"
        $updateBadge.FontWeight = "Bold"
        $infoPanel.Children.Add($updateBadge) | Out-Null
    }
    
    $stackPanel.Children.Add($infoPanel) | Out-Null
    
    [System.Windows.Controls.Grid]::SetColumn($stackPanel, 1)
    $grid.Children.Add($stackPanel) | Out-Null
    
    # Status indicator
    $statusText = New-Object System.Windows.Controls.TextBlock
    $statusText.FontSize = 12
    $statusText.VerticalAlignment = "Center"
    
    if ($source -eq $script:ModSourceType.Available) {
        $statusText.Text = "DL"
        $statusText.Foreground = "#FF607D8B"
        $statusText.FontWeight = "Bold"
        $statusText.ToolTip = "Click to download"
    }
    elseif ($enabled) {
        $statusText.Text = [char]0x2713  # Checkmark
        $statusText.Foreground = "#FF4CAF50"
        $statusText.ToolTip = "Enabled"
    }
    else {
        $statusText.Text = "-"
        $statusText.Foreground = "#FF808080"
        $statusText.ToolTip = "Disabled"
    }
    
    [System.Windows.Controls.Grid]::SetColumn($statusText, 2)
    $grid.Children.Add($statusText) | Out-Null
    
    $border.Child = $grid
    
    $item = New-Object System.Windows.Controls.ListBoxItem
    $item.Content = $border
    $item.Tag = $mod
    $item.Background = "Transparent"
    $item.BorderThickness = 0
    
    return $item
}

function Update-ModDetails {
    param($Mod)
    
    try {
        if (-not $Mod) {
            $window.FindName("EmptyStatePanel").Visibility = "Visible"
            $window.FindName("ModInfoPanel").Visibility = "Collapsed"
            $window.FindName("DescriptionExpander").Visibility = "Collapsed"
            $window.FindName("UpdateNoticePanel").Visibility = "Collapsed"
            $window.FindName("ParametersPanel").Visibility = "Collapsed"
            return
        }
        
        Write-Host "Loading details for: $($Mod['Name'])" -ForegroundColor Cyan
        $script:CurrentMod = $Mod
        
        $window.FindName("EmptyStatePanel").Visibility = "Collapsed"
        $window.FindName("ModInfoPanel").Visibility = "Visible"
        
        # Basic info
        $window.FindName("ModNameText").Text = $Mod['Name']
        $window.FindName("ModAuthorText").Text = $Mod['Author']
        $window.FindName("ModStatusText").Text = $Mod['Development Status']
        
        $statusBrush = New-Object System.Windows.Media.SolidColorBrush
        $statusBrush.Color = [System.Windows.Media.ColorConverter]::ConvertFromString((Get-ModStatusColor $Mod['Development Status'] $Mod['Enabled']))
        $window.FindName("ModStatusText").Foreground = $statusBrush
        
        $version = if ($Mod['InstalledVersion']) { $Mod['InstalledVersion'] } else { $Mod['Version'] }
        $window.FindName("ModVersionText").Text = $version
        $window.FindName("ModVersionBadgeText").Text = "v$version"
        
        $window.FindName("ModGameVersionText").Text = $Mod['Game Version Supported']
        $window.FindName("ModLastUpdatedText").Text = $Mod['Last Updated']
        
        # Source badge
        $sourceBadge = $window.FindName("ModSourceBadge")
        $sourceText = $window.FindName("ModSourceText")
        $sourceText.Text = $Mod['Source']
        $sourceBrush = New-Object System.Windows.Media.SolidColorBrush
        $sourceBrush.Color = [System.Windows.Media.ColorConverter]::ConvertFromString((Get-ModSourceColor $Mod['Source']))
        $sourceBadge.Background = $sourceBrush
        
        # Description
        if ($Mod['Description']) {
            $window.FindName("DescriptionExpander").Visibility = "Visible"
            $descriptionBlock = $window.FindName("ModDescriptionText")
            Convert-MarkdownToTextBlock $Mod['Description'] $descriptionBlock
        }
        else {
            $window.FindName("DescriptionExpander").Visibility = "Collapsed"
        }
        
        # Update notice
        if ($Mod['UpdateAvailable'] -and $Mod['LatestVersion']) {
            $window.FindName("UpdateNoticePanel").Visibility = "Visible"
            $window.FindName("UpdateVersionText").Text = "v$($Mod['LatestVersion'])"
            $window.FindName("UpdateNotesText").Text = "Click 'Update Available' to install the latest version."
        }
        else {
            $window.FindName("UpdateNoticePanel").Visibility = "Collapsed"
        }
        
        # Action buttons based on source and state
        $downloadBtn = $window.FindName("DownloadButton")
        $updateBtn = $window.FindName("UpdateButton")
        $removeBtn = $window.FindName("RemoveButton")
        $disableBtn = $window.FindName("DisableButton")
        $enableBtn = $window.FindName("EnableButton")
        
        # Hide all first
        $downloadBtn.Visibility = "Collapsed"
        $updateBtn.Visibility = "Collapsed"
        $removeBtn.Visibility = "Collapsed"
        $disableBtn.Visibility = "Collapsed"
        $enableBtn.Visibility = "Collapsed"
        
        switch ($Mod['Source']) {
            "Available" {
                $downloadBtn.Visibility = "Visible"
            }
            "Downloaded" {
                if ($Mod['UpdateAvailable']) {
                    $updateBtn.Visibility = "Visible"
                }
                $removeBtn.Visibility = "Visible"
            }
            "Manual" {
                if ($Mod['Enabled']) {
                    $disableBtn.Visibility = "Visible"
                }
                else {
                    $enableBtn.Visibility = "Visible"
                }
            }
        }
        
        # Parameters panel (only for installed mods)
        if ($Mod['Source'] -ne $script:ModSourceType.Available -and $Mod['Enabled']) {
            $paramPanel = $window.FindName("ParametersList")
            $paramPanel.Children.Clear()
            
            $currentModConfig = Get-ModConfig $Mod['ID']
            if (-not $script:Config.mod_parameters.ContainsKey($Mod['ID'])) {
                $script:Config.mod_parameters[$Mod['ID']] = $currentModConfig
            }
            
            $parameters = Get-ModParameters -Mod $Mod -CurrentConfig $currentModConfig
            
            if ($parameters -and $parameters.Count -gt 0) {
                $window.FindName("ParametersPanel").Visibility = "Visible"
                
                foreach ($param in $parameters) {
                    if ($param.ContainsKey('Visible') -and -not $param['Visible']) { continue }
                    if ($param['Type'] -eq 'section') {
                        $sectionHeader = New-Object System.Windows.Controls.TextBlock
                        $sectionHeader.Text = $param['Label']
                        $sectionHeader.FontWeight = "Bold"
                        $sectionHeader.FontSize = 13
                        $sectionHeader.Margin = "0,15,0,5"
                        $sectionHeader.Foreground = "#FF0078D4"
                        $paramPanel.Children.Add($sectionHeader) | Out-Null
                        continue
                    }
                    
                    if ($param['Type'] -in @('info', 'warning')) { continue }
                    
                    $currentValue = if ($currentModConfig.ContainsKey($param['Name'])) {
                        $currentModConfig[$param['Name']]
                    }
                    else {
                        $param['Default']
                    }
                    
                    $control = New-ParameterControl $Mod['ID'] $param $currentValue
                    $paramPanel.Children.Add($control) | Out-Null
                }
            }
            else {
                $window.FindName("ParametersPanel").Visibility = "Collapsed"
            }
        }
        else {
            $window.FindName("ParametersPanel").Visibility = "Collapsed"
        }
        
    }
    catch {
        Write-Host "[ERROR] Update-ModDetails: $_" -ForegroundColor Red
    }
}

function New-ParameterControl {
    param($ModId, $Param, $CurrentValue)
    
    $border = New-Object System.Windows.Controls.Border
    $border.BorderThickness = "1"
    $border.BorderBrush = "#FFDDDDDD"
    $border.Background = "#FFFAFAFA"
    $border.Padding = "10"
    $border.Margin = "0,0,0,8"
    
    $stack = New-Object System.Windows.Controls.StackPanel
    
    $label = New-Object System.Windows.Controls.TextBlock
    $label.Text = $Param['Label']
    $label.FontWeight = "SemiBold"
    $label.Margin = "0,0,0,3"
    $stack.Children.Add($label) | Out-Null
    
    if ($Param.ContainsKey('Description')) {
        $desc = New-Object System.Windows.Controls.TextBlock
        $desc.Text = $Param['Description']
        $desc.FontSize = 11
        $desc.Foreground = "#FF666666"
        $desc.TextWrapping = "Wrap"
        $desc.Margin = "0,0,0,8"
        $stack.Children.Add($desc) | Out-Null
    }
    
    $control = $null
    
    switch ($Param['Type']) {
        'boolean' {
            $control = New-Object System.Windows.Controls.CheckBox
            $control.IsChecked = $CurrentValue
            $control.Content = if ($CurrentValue) { "Enabled" } else { "Disabled" }
            $control.Tag = @{ ModId = $ModId; ParamName = $Param['Name']; Type = 'boolean' }
            $control.Add_Checked({
                $tag = $this.Tag
                if (-not $script:Config.mod_parameters.ContainsKey($tag.ModId)) {
                    $script:Config.mod_parameters[$tag.ModId] = @{}
                }
                $script:Config.mod_parameters[$tag.ModId][$tag.ParamName] = $true
                $this.Content = "Enabled"
            })
            $control.Add_Unchecked({
                $tag = $this.Tag
                if (-not $script:Config.mod_parameters.ContainsKey($tag.ModId)) {
                    $script:Config.mod_parameters[$tag.ModId] = @{}
                }
                $script:Config.mod_parameters[$tag.ModId][$tag.ParamName] = $false
                $this.Content = "Disabled"
            })
        }
        
        'select' {
            $control = New-Object System.Windows.Controls.ComboBox
            foreach ($opt in $Param['Options']) {
                $control.Items.Add($opt) | Out-Null
            }
            $control.SelectedItem = $CurrentValue
            $control.Tag = @{ ModId = $ModId; ParamName = $Param['Name']; Type = 'select' }
            $control.Add_SelectionChanged({
                $tag = $this.Tag
                if (-not $script:Config.mod_parameters.ContainsKey($tag.ModId)) {
                    $script:Config.mod_parameters[$tag.ModId] = @{}
                }
                $script:Config.mod_parameters[$tag.ModId][$tag.ParamName] = $this.SelectedItem
            })
        }
        
        'integer' {
            $grid = New-Object System.Windows.Controls.Grid
            $c1 = New-Object System.Windows.Controls.ColumnDefinition
            $c1.Width = "*"
            $c2 = New-Object System.Windows.Controls.ColumnDefinition
            $c2.Width = "60"
            $grid.ColumnDefinitions.Add($c1)
            $grid.ColumnDefinitions.Add($c2)
            
            $slider = New-Object System.Windows.Controls.Slider
            $slider.Minimum = if ($Param.ContainsKey('Min')) { $Param['Min'] } else { 0 }
            $slider.Maximum = if ($Param.ContainsKey('Max')) { $Param['Max'] } else { 100 }
            $slider.Value = $CurrentValue
            $slider.IsSnapToTickEnabled = $true
            $slider.TickFrequency = 1
            $slider.Tag = @{ ModId = $ModId; ParamName = $Param['Name']; Type = 'integer'; IsUpdating = $false }
            
            $valueBox = New-Object System.Windows.Controls.TextBox
            $valueBox.Text = $CurrentValue
            $valueBox.Margin = "5,0,0,0"
            $valueBox.Tag = @{ Slider = $slider; ModId = $ModId; ParamName = $Param['Name']; IsUpdating = $false }
            
            # Slider updates textbox and config
            $slider.Add_ValueChanged({
                $tag = $this.Tag
                if ($tag.IsUpdating) { return }
                
                $intVal = [int]$this.Value
                if (-not $script:Config.mod_parameters.ContainsKey($tag.ModId)) {
                    $script:Config.mod_parameters[$tag.ModId] = @{}
                }
                $script:Config.mod_parameters[$tag.ModId][$tag.ParamName] = $intVal
                
                # Update textbox
                $grid = $this.Parent
                $textBox = $grid.Children[1]
                $textBox.Tag.IsUpdating = $true
                $textBox.Text = $intVal.ToString()
                $textBox.Tag.IsUpdating = $false
            })
            
            # Textbox updates slider and config
            $valueBox.Add_TextChanged({
                $tag = $this.Tag
                if ($tag.IsUpdating) { return }
                
                $value = 0
                if ([int]::TryParse($this.Text, [ref]$value)) {
                    $slider = $tag.Slider
                    if ($value -ge $slider.Minimum -and $value -le $slider.Maximum) {
                        $slider.Tag.IsUpdating = $true
                        $slider.Value = $value
                        $slider.Tag.IsUpdating = $false
                        
                        if (-not $script:Config.mod_parameters.ContainsKey($tag.ModId)) {
                            $script:Config.mod_parameters[$tag.ModId] = @{}
                        }
                        $script:Config.mod_parameters[$tag.ModId][$tag.ParamName] = $value
                    }
                }
            })
            
            [System.Windows.Controls.Grid]::SetColumn($slider, 0)
            [System.Windows.Controls.Grid]::SetColumn($valueBox, 1)
            $grid.Children.Add($slider) | Out-Null
            $grid.Children.Add($valueBox) | Out-Null
            
            $control = $grid
        }
        
        'number' {
            $grid = New-Object System.Windows.Controls.Grid
            $c1 = New-Object System.Windows.Controls.ColumnDefinition
            $c1.Width = "*"
            $c2 = New-Object System.Windows.Controls.ColumnDefinition
            $c2.Width = "60"
            $grid.ColumnDefinitions.Add($c1)
            $grid.ColumnDefinitions.Add($c2)
            
            $slider = New-Object System.Windows.Controls.Slider
            $slider.Minimum = if ($Param.ContainsKey('Min')) { $Param['Min'] } else { 0 }
            $slider.Maximum = if ($Param.ContainsKey('Max')) { $Param['Max'] } else { 100 }
            $slider.Value = $CurrentValue
            $step = if ($Param.ContainsKey('Step')) { $Param['Step'] } else { 0.1 }
            $slider.TickFrequency = $step
            $slider.IsSnapToTickEnabled = $true
            $slider.Tag = @{ ModId = $ModId; ParamName = $Param['Name']; Type = 'number'; IsUpdating = $false }
            
            $valueBox = New-Object System.Windows.Controls.TextBox
            $valueBox.Text = $CurrentValue
            $valueBox.Margin = "5,0,0,0"
            $valueBox.Tag = @{ Slider = $slider; ModId = $ModId; ParamName = $Param['Name']; IsUpdating = $false }
            
            # Slider updates textbox and config
            $slider.Add_ValueChanged({
                $tag = $this.Tag
                if ($tag.IsUpdating) { return }
                
                $doubleVal = [double]$this.Value
                if (-not $script:Config.mod_parameters.ContainsKey($tag.ModId)) {
                    $script:Config.mod_parameters[$tag.ModId] = @{}
                }
                $script:Config.mod_parameters[$tag.ModId][$tag.ParamName] = $doubleVal
                
                # Update textbox
                $grid = $this.Parent
                $textBox = $grid.Children[1]
                $textBox.Tag.IsUpdating = $true
                $textBox.Text = $doubleVal.ToString("F2")
                $textBox.Tag.IsUpdating = $false
            })
            
            # Textbox updates slider and config
            $valueBox.Add_TextChanged({
                $tag = $this.Tag
                if ($tag.IsUpdating) { return }
                
                $value = 0.0
                if ([double]::TryParse($this.Text, [ref]$value)) {
                    $slider = $tag.Slider
                    if ($value -ge $slider.Minimum -and $value -le $slider.Maximum) {
                        $slider.Tag.IsUpdating = $true
                        $slider.Value = $value
                        $slider.Tag.IsUpdating = $false
                        
                        if (-not $script:Config.mod_parameters.ContainsKey($tag.ModId)) {
                            $script:Config.mod_parameters[$tag.ModId] = @{}
                        }
                        $script:Config.mod_parameters[$tag.ModId][$tag.ParamName] = $value
                    }
                }
            })
            
            [System.Windows.Controls.Grid]::SetColumn($slider, 0)
            [System.Windows.Controls.Grid]::SetColumn($valueBox, 1)
            $grid.Children.Add($slider) | Out-Null
            $grid.Children.Add($valueBox) | Out-Null
            
            $control = $grid
        }
        
        'string' {
            $control = New-Object System.Windows.Controls.TextBox
            $control.Text = $CurrentValue
            $control.Tag = @{ ModId = $ModId; ParamName = $Param['Name']; Type = 'string' }
            $control.Add_TextChanged({
                $tag = $this.Tag
                if (-not $script:Config.mod_parameters.ContainsKey($tag.ModId)) {
                    $script:Config.mod_parameters[$tag.ModId] = @{}
                }
                $script:Config.mod_parameters[$tag.ModId][$tag.ParamName] = $this.Text
            })
        }
    }
    
    if ($control) {
        $stack.Children.Add($control) | Out-Null
    }
    
    $border.Child = $stack
    return $border
}

#endregion

#region Alias Management

function Update-AliasList {
    param($ListBox)
    
    try {
        $ListBox.Items.Clear()
        
        foreach ($alias in ($script:CmdAliases.GetEnumerator() | Sort-Object Key)) {
            $border = New-Object System.Windows.Controls.Border
            $border.Padding = "8"
            $border.Margin = "0,2"
            
            $stack = New-Object System.Windows.Controls.StackPanel
            
            $nameText = New-Object System.Windows.Controls.TextBlock
            $nameText.Text = $alias.Key
            $nameText.FontWeight = "Bold"
            $nameText.FontFamily = "Consolas"
            $stack.Children.Add($nameText) | Out-Null
            
            $cmdText = New-Object System.Windows.Controls.TextBlock
            $cmdText.Text = $alias.Value
            $cmdText.FontSize = 10
            $cmdText.Foreground = "#FF666666"
            $cmdText.FontFamily = "Consolas"
            $cmdText.TextTrimming = "CharacterEllipsis"
            $stack.Children.Add($cmdText) | Out-Null
            
            $border.Child = $stack
            
            $item = New-Object System.Windows.Controls.ListBoxItem
            $item.Content = $border
            $item.Tag = @{ Name = $alias.Key; Command = $alias.Value }
            
            $ListBox.Items.Add($item) | Out-Null
        }
    }
    catch {
        Write-Host "[ERROR] Update-AliasList: $_" -ForegroundColor Red
    }
}

function Show-AliasEditor {
    param(
        [string]$AliasName = "",
        [string]$AliasCommand = "",
        [bool]$IsNew = $false
    )
    
    $window.FindName("AliasEmptyState").Visibility = "Collapsed"
    $window.FindName("AliasEditorPanel").Visibility = "Visible"
    
    $window.FindName("AliasNameBox").Text = $AliasName
    $window.FindName("AliasCommandBox").Text = $AliasCommand
    $window.FindName("AliasNameBox").IsReadOnly = -not $IsNew
}

function Hide-AliasEditor {
    $window.FindName("AliasEmptyState").Visibility = "Visible"
    $window.FindName("AliasEditorPanel").Visibility = "Collapsed"
}

#endregion

#region Main Execution

try {
    # Load XAML
    $reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xaml))
    $window = [System.Windows.Markup.XamlReader]::Load($reader)
    
    # Get UI controls early for LuaJIT check
    $progressBar = $window.FindName("DownloadProgressBar")
    $downloadStatusText = $window.FindName("DownloadStatusText")
    $statusText = $window.FindName("StatusText")
    
    # Check for LuaJIT installation
    if (-not (Test-LuaJitInstalled)) {
        Write-Host "[WARN] LuaJIT not found at: $script:LuaJitPath" -ForegroundColor Yellow
        $statusText.Text = "LuaJIT runtime missing - prompting user..."
        $window.Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
        
        # Show window first so the dialogs have a parent
        $window.Show()
        $window.Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
        
        Show-LuaJitPrompt -ProgressBar $progressBar -StatusText $downloadStatusText
    }
    else {
        Write-Host "[OK] LuaJIT found at: $script:LuaJitPath" -ForegroundColor Green
    }
    
    # Load mod cache
    Load-ModCache
    
    # Initialize config
    $script:Config = @{
        mod_parameters = @{}
    }
    
    # Load settings
    $script:Settings = Get-GameSettings
    
    # Get remaining UI controls
    $modListBox = $window.FindName("ModListBox")
    
    # Filter controls
    $filterAll = $window.FindName("FilterAll")
    $filterInstalled = $window.FindName("FilterInstalled")
    $filterAvailable = $window.FindName("FilterAvailable")
    
    # Action buttons
    $downloadButton = $window.FindName("DownloadButton")
    $updateButton = $window.FindName("UpdateButton")
    $removeButton = $window.FindName("RemoveButton")
    $disableButton = $window.FindName("DisableButton")
    $enableButton = $window.FindName("EnableButton")
    $launchGameButton = $window.FindName("LaunchGameButton")
    $refreshButton = $window.FindName("RefreshButton")
    $saveButton = $window.FindName("SaveButton")
    $saveAllButton = $window.FindName("SaveAllButton")
    $resetModButton = $window.FindName("ResetModButton")
    $exitButton = $window.FindName("ExitButton")
    
    # Alias controls
    $aliasListBox = $window.FindName("AliasListBox")
    $addAliasButton = $window.FindName("AddAliasButton")
    $deleteAliasButton = $window.FindName("DeleteAliasButton")
    $saveAliasesButton = $window.FindName("SaveAliasesButton")
    $cancelAliasButton = $window.FindName("CancelAliasButton")
    $applyAliasButton = $window.FindName("ApplyAliasButton")
    
    # Initial load
    $statusText.Text = "Fetching available mods from GitHub..."
    $window.Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
    
    # Fetch GitHub releases
    $script:GitHubReleases = Get-GitHubReleases
    
    # Load installed mods
    $script:InstalledMods = Get-InstalledMods
    
    # Combine into all mods list
    $script:AllMods = Get-AllMods $script:GitHubReleases
    
    # Populate mod list
    Update-ModList $modListBox "All"
    
    # Populate alias list
    if ($script:Settings) {
        Update-AliasList $aliasListBox
    }
    
    # Update status
    $installedCount = ($script:AllMods | Where-Object { $_['Source'] -ne $script:ModSourceType.Available }).Count
    $availableCount = ($script:AllMods | Where-Object { $_['Source'] -eq $script:ModSourceType.Available }).Count
    $statusText.Text = "$installedCount installed, $availableCount available - Ready"
    
    #region Event Handlers
    
    # Filter handlers
    $filterAll.Add_Checked({ Update-ModList $modListBox "All" })
    $filterInstalled.Add_Checked({ Update-ModList $modListBox "Installed" })
    $filterAvailable.Add_Checked({ Update-ModList $modListBox "Available" })
    
    # Mod list selection
    $modListBox.Add_SelectionChanged({
        if ($this.SelectedItem) {
            Update-ModDetails $this.SelectedItem.Tag
        }
    })
    
    # Download button
    $downloadButton.Add_Click({
        if ($script:CurrentMod -and $script:CurrentMod['ReleaseInfo']) {
            $result = Download-ModFromGitHub $script:CurrentMod['ReleaseInfo'] $progressBar $downloadStatusText
            if ($result) {
                # Refresh
                $script:InstalledMods = Get-InstalledMods
                $script:AllMods = Get-AllMods $script:GitHubReleases
                $currentFilter = if ($filterInstalled.IsChecked) { "Installed" } elseif ($filterAvailable.IsChecked) { "Available" } else { "All" }
                Update-ModList $modListBox $currentFilter
                
                # Update status
                $installedCount = ($script:AllMods | Where-Object { $_['Source'] -ne $script:ModSourceType.Available }).Count
                $availableCount = ($script:AllMods | Where-Object { $_['Source'] -eq $script:ModSourceType.Available }).Count
                $statusText.Text = "$installedCount installed, $availableCount available - Ready"
                
                [System.Windows.MessageBox]::Show("Mod installed successfully!", "Success", "OK", "Information")
            }
        }
    })
    
    # Update button
    $updateButton.Add_Click({
        if ($script:CurrentMod -and $script:CurrentMod['ReleaseInfo']) {
            $result = Download-ModFromGitHub $script:CurrentMod['ReleaseInfo'] $progressBar $downloadStatusText
            if ($result) {
                $script:InstalledMods = Get-InstalledMods
                $script:AllMods = Get-AllMods $script:GitHubReleases
                $currentFilter = if ($filterInstalled.IsChecked) { "Installed" } elseif ($filterAvailable.IsChecked) { "Available" } else { "All" }
                Update-ModList $modListBox $currentFilter
                [System.Windows.MessageBox]::Show("Mod updated successfully!", "Success", "OK", "Information")
            }
        }
    })
    
    # Remove button (for downloaded mods)
    $removeButton.Add_Click({
        if ($script:CurrentMod) {
            $confirm = [System.Windows.MessageBox]::Show(
                "Are you sure you want to remove '$($script:CurrentMod['Name'])'?`n`nThis will delete the mod from your computer.",
                "Confirm Removal",
                "YesNo",
                "Warning"
            )
            
            if ($confirm -eq "Yes") {
                $result = Remove-DownloadedMod $script:CurrentMod['Folder']
                if ($result) {
                    $script:InstalledMods = Get-InstalledMods
                    $script:AllMods = Get-AllMods $script:GitHubReleases
                    $currentFilter = if ($filterInstalled.IsChecked) { "Installed" } elseif ($filterAvailable.IsChecked) { "Available" } else { "All" }
                    Update-ModList $modListBox $currentFilter
                    Update-ModDetails $null
                    
                    $installedCount = ($script:AllMods | Where-Object { $_['Source'] -ne $script:ModSourceType.Available }).Count
                    $availableCount = ($script:AllMods | Where-Object { $_['Source'] -eq $script:ModSourceType.Available }).Count
                    $statusText.Text = "$installedCount installed, $availableCount available - Ready"
                }
            }
        }
    })
    
    # Disable button (for manual mods)
    $disableButton.Add_Click({
        if ($script:CurrentMod) {
            Set-ModEnabled $script:CurrentMod $false
            $script:InstalledMods = Get-InstalledMods
            $script:AllMods = Get-AllMods $script:GitHubReleases
            $currentFilter = if ($filterInstalled.IsChecked) { "Installed" } elseif ($filterAvailable.IsChecked) { "Available" } else { "All" }
            Update-ModList $modListBox $currentFilter
            Update-ModDetails $null
        }
    })
    
    # Enable button (for manual mods)
    $enableButton.Add_Click({
        if ($script:CurrentMod) {
            Set-ModEnabled $script:CurrentMod $true
            $script:InstalledMods = Get-InstalledMods
            $script:AllMods = Get-AllMods $script:GitHubReleases
            $currentFilter = if ($filterInstalled.IsChecked) { "Installed" } elseif ($filterAvailable.IsChecked) { "Available" } else { "All" }
            Update-ModList $modListBox $currentFilter
        }
    })
    
    # Refresh button
    $refreshButton.Add_Click({
        $statusText.Text = "Refreshing..."
        $window.Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
        
        $script:GitHubReleases = Get-GitHubReleases
        $script:InstalledMods = Get-InstalledMods
        $script:AllMods = Get-AllMods $script:GitHubReleases
        $currentFilter = if ($filterInstalled.IsChecked) { "Installed" } elseif ($filterAvailable.IsChecked) { "Available" } else { "All" }
        Update-ModList $modListBox $currentFilter
        
        $installedCount = ($script:AllMods | Where-Object { $_['Source'] -ne $script:ModSourceType.Available }).Count
        $availableCount = ($script:AllMods | Where-Object { $_['Source'] -eq $script:ModSourceType.Available }).Count
        $statusText.Text = "$installedCount installed, $availableCount available - Ready"
    })
    
    # Launch game
    $launchGameButton.Add_Click({
        Write-Host "Launching game via Steam..." -ForegroundColor Cyan
        Start-Process "steam://rungameid/2939600"
        Start-Sleep -Milliseconds 500
        $window.Close()
    })
    
    # Save button
    $saveButton.Add_Click({
        if ($script:CurrentMod -and $script:Config.mod_parameters.ContainsKey($script:CurrentMod['ID'])) {
            $result = Save-ModConfig $script:CurrentMod['ID'] $script:Config.mod_parameters[$script:CurrentMod['ID']]
            if ($result) {
                [System.Windows.MessageBox]::Show("Configuration saved!", "Success", "OK", "Information")
            }
            else {
                [System.Windows.MessageBox]::Show("Failed to save configuration.", "Error", "OK", "Error")
            }
        }
    })
    
    # Save all
    $saveAllButton.Add_Click({
        $savedCount = 0
        foreach ($modId in $script:Config.mod_parameters.Keys) {
            if (Save-ModConfig $modId $script:Config.mod_parameters[$modId]) {
                $savedCount++
            }
        }
        [System.Windows.MessageBox]::Show("Saved $savedCount mod configuration(s).", "Save Complete", "OK", "Information")
    })
    
    # Reset mod
    $resetModButton.Add_Click({
        if ($script:CurrentMod) {
            $confirm = [System.Windows.MessageBox]::Show(
                "Reset all parameters for '$($script:CurrentMod['Name'])' to defaults?",
                "Confirm Reset",
                "YesNo",
                "Question"
            )
            
            if ($confirm -eq "Yes") {
                $script:Config.mod_parameters.Remove($script:CurrentMod['ID'])
                Update-ModDetails $script:CurrentMod
            }
        }
    })
    
    # Alias handlers
    $aliasListBox.Add_SelectionChanged({
        if ($this.SelectedItem) {
            $tag = $this.SelectedItem.Tag
            Show-AliasEditor $tag.Name $tag.Command $false
        }
    })
    
    $addAliasButton.Add_Click({
        Show-AliasEditor "" "" $true
    })
    
    $deleteAliasButton.Add_Click({
        if ($aliasListBox.SelectedItem) {
            $name = $aliasListBox.SelectedItem.Tag.Name
            $confirm = [System.Windows.MessageBox]::Show("Delete alias '$name'?", "Confirm Delete", "YesNo", "Question")
            if ($confirm -eq "Yes") {
                $script:CmdAliases.Remove($name)
                Update-AliasList $aliasListBox
                Hide-AliasEditor
            }
        }
    })
    
    $saveAliasesButton.Add_Click({
        if ($script:Settings) {
            if (Save-GameSettings $script:Settings) {
                [System.Windows.MessageBox]::Show("Aliases saved!", "Success", "OK", "Information")
            }
        }
    })
    
    $cancelAliasButton.Add_Click({
        Hide-AliasEditor
        $aliasListBox.SelectedItem = $null
    })
    
    $applyAliasButton.Add_Click({
        $name = $window.FindName("AliasNameBox").Text.Trim()
        $command = $window.FindName("AliasCommandBox").Text.Trim()
        
        if ([string]::IsNullOrWhiteSpace($name)) {
            [System.Windows.MessageBox]::Show("Please enter an alias name.", "Validation", "OK", "Warning")
            return
        }
        
        $script:CmdAliases[$name] = $command
        Update-AliasList $aliasListBox
        Hide-AliasEditor
    })
    
    # Exit
    $exitButton.Add_Click({
        $window.Close()
    })
    
    #endregion
    
    # Show window (if not already shown for LuaJIT prompt)
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host "Opening GUI window..." -ForegroundColor Cyan
    Write-Host "======================================" -ForegroundColor Cyan
    if (-not $window.IsVisible) {
        $window.ShowDialog() | Out-Null
    }
    else {
        # Window was already shown for LuaJIT prompt, run message loop until closed
        $frame = New-Object System.Windows.Threading.DispatcherFrame
        $window.Add_Closed({
            param($sender, $eventArgs)
            $frame.Continue = $false
        })
        [System.Windows.Threading.Dispatcher]::PushFrame($frame)
    }
}
catch {
    Write-Host "FATAL ERROR: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Yellow
    [System.Windows.MessageBox]::Show(
        "Fatal error: $_`n`n$($_.ScriptStackTrace)",
        "Error",
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Error
    )
}

#endregion
