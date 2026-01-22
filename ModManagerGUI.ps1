#Requires -Version 5.1

<#
.SYNOPSIS
    The Network Inc - WPF Mod Manager
.DESCRIPTION
    A Windows Presentation Foundation GUI for managing TNI mods.
    Provides a modern, user-friendly interface for configuration.
.NOTES
    Author: Chris
    Version: 2.0
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
$script:ConfigFileName = "entry.lua"

# Startup logging
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "TNI Mod Manager - Starting up..." -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Game Data Path:          " -NoNewline -ForegroundColor Gray
Write-Host $script:GameDataPath -ForegroundColor White
Write-Host "  Mods Directory:          " -NoNewline -ForegroundColor Gray
Write-Host $script:ModsDirectory -ForegroundColor White
Write-Host "  Settings File:           " -NoNewline -ForegroundColor Gray
Write-Host $script:SettingsPath -ForegroundColor White
Write-Host "  Config Storage:          " -NoNewline -ForegroundColor Gray
Write-Host "Embedded in entry.lua files" -ForegroundColor White
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
$script:Mods = @()
$script:CurrentMod = $null
$script:Settings = $null
$script:CmdAliases = @{}

# Helper function to parse simple markdown to WPF TextBlock
function ConvertFrom-MarkdownToTextBlock {
    param([string]$Text)
    
    $textBlock = New-Object System.Windows.Controls.TextBlock
    $textBlock.TextWrapping = "Wrap"
    
    # Simple markdown parsing
    $lines = $Text -split "`r?`n"
    foreach ($line in $lines) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            $textBlock.Inlines.Add((New-Object System.Windows.Documents.LineBreak))
            continue
        }
        
        $pos = 0
        while ($pos -lt $line.Length) {
            # Bold **text**
            if ($line.Substring($pos) -match '^\*\*([^\*]+)\*\*') {
                $run = New-Object System.Windows.Documents.Run
                $run.Text = $Matches[1]
                $run.FontWeight = "Bold"
                $textBlock.Inlines.Add($run)
                $pos += $Matches[0].Length
            }
            # Italic *text*
            elseif ($line.Substring($pos) -match '^\*([^\*]+)\*') {
                $run = New-Object System.Windows.Documents.Run
                $run.Text = $Matches[1]
                $run.FontStyle = "Italic"
                $textBlock.Inlines.Add($run)
                $pos += $Matches[0].Length
            }
            # Links [text](url)
            elseif ($line.Substring($pos) -match '^\[([^\]]+)\]\(([^\)]+)\)') {
                $hyperlink = New-Object System.Windows.Documents.Hyperlink
                $hyperlink.Inlines.Add($Matches[1])
                $hyperlink.NavigateUri = $Matches[2]
                $hyperlink.Add_RequestNavigate({
                        param($sender, $e)
                        Start-Process $e.Uri.AbsoluteUri
                    })
                $textBlock.Inlines.Add($hyperlink)
                $pos += $Matches[0].Length
            }
            # Code `text`
            elseif ($line.Substring($pos) -match '^`([^`]+)`') {
                $run = New-Object System.Windows.Documents.Run
                $run.Text = $Matches[1]
                $run.FontFamily = "Consolas"
                $textBlock.Inlines.Add($run)
                $pos += $Matches[0].Length
            }
            else {
                # Regular text
                $nextSpecial = [regex]::Match($line.Substring($pos), '(\*\*|\*|\[|`)').Index
                if ($nextSpecial -eq -1) {
                    $textBlock.Inlines.Add($line.Substring($pos))
                    break
                }
                else {
                    $textBlock.Inlines.Add($line.Substring($pos, $nextSpecial))
                    $pos += $nextSpecial
                }
            }
        }
        $textBlock.Inlines.Add((New-Object System.Windows.Documents.LineBreak))
    }
    
    return $textBlock
}

# Get color for mod status
function Get-ModStatusColor {
    param(
        [string]$Status,
        [bool]$Enabled
    )
    
    $colors = @{
        'Active'       = @{ Enabled = '#FF4CAF50'; Disabled = '#FF2E7D32' }  # Green
        'Maintenance'  = @{ Enabled = '#FFFFD54F'; Disabled = '#FFF9A825' }  # Yellow
        'Discontinued' = @{ Enabled = '#FFFF9800'; Disabled = '#FFE65100' }  # Orange
        'Unsupported'  = @{ Enabled = '#FFF44336'; Disabled = '#FFC62828' }  # Red
        'Defunct'      = @{ Enabled = '#FFF44336'; Disabled = '#FFC62828' }  # Red
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

# XAML for the main window
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="The Network Inc - Mod Manager" 
        Height="700" Width="1000" 
        WindowStartupLocation="CenterScreen"
        Background="#FF37474F">
    <Window.Resources>
        <Style TargetType="Button">
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
                       HorizontalAlignment="Center"/>
        </StackPanel>
        
        <!-- Main Content -->
        <TabControl Grid.Row="1" Background="Transparent" BorderThickness="0">
            <!-- Mods Tab -->
            <TabItem Header="Mods Management" FontSize="13">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="300"/>
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
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    
                    <TextBlock Grid.Row="0" 
                               Text="Installed Mods" 
                               FontSize="14" 
                               FontWeight="Bold"
                               Margin="10,10,10,5"/>
                    
                    <ListBox Name="ModListBox" 
                             Grid.Row="1"
                             BorderThickness="0"
                             Margin="5"
                             ScrollViewer.HorizontalScrollBarVisibility="Disabled">
                        <ListBox.ItemTemplate>
                            <DataTemplate>
                                <Grid Margin="0,5">
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="Auto"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
                                    <CheckBox Grid.Column="0" 
                                              IsChecked="{Binding Enabled}"
                                              Margin="0,0,10,0"
                                              VerticalAlignment="Center"/>
                                    <StackPanel Grid.Column="1">
                                        <TextBlock Text="{Binding Name}" 
                                                   FontWeight="Bold"
                                                   TextWrapping="Wrap"/>
                                        <TextBlock Text="{Binding ID}" 
                                                   FontSize="10"
                                                   Foreground="#FFAAAAAA"/>
                                    </StackPanel>
                                </Grid>
                            </DataTemplate>
                        </ListBox.ItemTemplate>
                    </ListBox>
                    
                    <StackPanel Grid.Row="2" Margin="5">
                        <Button Name="LaunchGameButton" Content="Launch Game" Background="#FF107C10" Foreground="White">
                            <Button.Style>
                                <Style TargetType="Button">
                                    <Setter Property="Background" Value="#FF107C10"/>
                                    <Setter Property="Foreground" Value="White"/>
                                    <Setter Property="Padding" Value="10,5"/>
                                    <Setter Property="Margin" Value="5"/>
                                    <Setter Property="FontSize" Value="12"/>
                                    <Setter Property="FontWeight" Value="Bold"/>
                                    <Setter Property="Cursor" Value="Hand"/>
                                    <Style.Triggers>
                                        <Trigger Property="IsMouseOver" Value="True">
                                            <Setter Property="Background" Value="#FF0E6A0E"/>
                                        </Trigger>
                                    </Style.Triggers>
                                </Style>
                            </Button.Style>
                        </Button>
                        <Button Name="EnableAllButton" Content="Enable All" />
                        <Button Name="DisableAllButton" Content="Disable All" />
                        <Button Name="RefreshButton" Content="Refresh List" />
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
                    <Grid Name="DetailsPanel" Margin="10">
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="Auto"/>
                        </Grid.RowDefinitions>
                    
                    <!-- Mod Info -->
                    <StackPanel Grid.Row="0" Name="ModInfoPanel" Visibility="Collapsed">
                        <TextBlock Name="ModNameText" 
                                   FontSize="18" 
                                   FontWeight="Bold"
                                   Margin="0,0,0,5"/>
                        <Grid Margin="0,0,0,10">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <Grid.RowDefinitions>
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
                        </Grid>
                    </StackPanel>
                    
                    <!-- Description -->
                    <Expander Grid.Row="1" 
                              Name="DescriptionExpander"
                              Header="Description" 
                              IsExpanded="True"
                              Visibility="Collapsed"
                              Margin="0,5">
                        <Border Name="ModDescriptionBorder" 
                                Padding="10"
                                MaxHeight="150">
                            <ScrollViewer VerticalScrollBarVisibility="Auto">
                                <ContentControl Name="ModDescriptionText" />
                            </ScrollViewer>
                        </Border>
                    </Expander>
                    
                    <!-- Parameters -->
                    <StackPanel Grid.Row="2" Name="ParametersPanel" Visibility="Collapsed" Margin="0,10,0,0">
                        <TextBlock Text="Configuration Parameters" 
                                   FontSize="14" 
                                   FontWeight="Bold"
                                   Margin="0,0,0,10"/>
                        <StackPanel Name="ParametersList"/>
                    </StackPanel>
                    
                    <!-- Empty State -->
                    <StackPanel Grid.Row="3" 
                                Name="EmptyStatePanel"
                                VerticalAlignment="Center"
                                HorizontalAlignment="Center"
                                Margin="0,50,0,0">
                        <TextBlock Text="Select a mod to view details" 
                                   FontSize="16"
                                   HorizontalAlignment="Center"/>
                    </StackPanel>
                    
                    <!-- Action Buttons -->
                    <StackPanel Grid.Row="3" 
                                Name="ActionButtonsPanel"
                                Orientation="Horizontal" 
                                HorizontalAlignment="Right"
                                Visibility="Collapsed"
                                Margin="0,10,0,0">
                        <Button Name="ResetModButton" Content="Reset to Defaults" Width="130"/>
                        <Button Name="SaveButton" Content="Save Changes" Width="120"/>
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
                                <Button Name="AddAliasButton" Content="+ New Alias" Background="#FF107C10" Foreground="White"/>
                                <Button Name="DeleteAliasButton" Content="Delete Alias" Background="#FFD13438" Foreground="White"/>
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
                                        <Button Name="ApplyAliasButton" Content="Apply" Width="100"/>
                                    </StackPanel>
                                </StackPanel>
                            </Grid>
                        </ScrollViewer>
                    </Border>
                </Grid>
            </TabItem>
        </TabControl>
        
        
        <!-- Footer -->
        <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,10,0,0">
            <Button Name="SaveAllButton" Content="Save All Changes" Width="150" Height="30"/>
            <Button Name="ResetAllButton" Content="Reset All to Defaults" Width="150" Height="30"/>
            <Button Name="ExitButton" Content="Exit" Width="100" Height="30"/>
        </StackPanel>
    </Grid>
</Window>
"@

# YAML Parser
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
            # Save previous parameter with any pending multiline content
            if ($currentParam) {
                if ($inParamMultiline -and $paramMultilineKey) {
                    $currentParam[$paramMultilineKey] = $paramMultilineValue -join "`n"
                    $inParamMultiline = $false
                    $paramMultilineKey = $null
                }
                $parameters += $currentParam
            }
            $currentParam = @{ Name = $Matches[1].Trim() }
            continue
        }
        
        # Handle multiline parameter properties (e.g., Description: |)
        if ($inParameters -and $currentParam -and $line -match '^\s{4}(\w+):\s*\|') {
            # Save any previous multiline value first
            if ($inParamMultiline -and $paramMultilineKey) {
                $currentParam[$paramMultilineKey] = $paramMultilineValue -join "`n"
            }
            $paramMultilineKey = $Matches[1]
            $inParamMultiline = $true
            $paramMultilineValue = @()
            continue
        }
        
        # Handle multiline parameter property content (6+ spaces indentation)
        if ($inParamMultiline -and $line -match '^\s{6,}(.+)') {
            $paramMultilineValue += $Matches[1]
            continue
        }
        
        # End of multiline parameter property
        if ($inParamMultiline -and $line -match '^\s{4}(\w+):\s*(.*)') {
            # Save the multiline value
            $currentParam[$paramMultilineKey] = $paramMultilineValue -join "`n"
            $inParamMultiline = $false
            $paramMultilineKey = $null
            
            # Now process this new single-line property
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
        # Save any pending multiline parameter content
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

# Get installed mods
function Get-InstalledMods {
    Write-Host "Scanning for mods in $script:ModsDirectory..." -ForegroundColor Cyan
    $mods = @()
    
    if (-not (Test-Path $script:ModsDirectory)) {
        Write-Host "[WARN] Mods directory not found: $script:ModsDirectory" -ForegroundColor Yellow
        return $mods
    }
    
    $modFolders = Get-ChildItem -Path $script:ModsDirectory -Directory | 
    Where-Object { $_.Name -ne '.lua-typing' }
    
    foreach ($folder in $modFolders) {
        $metadataPath = Join-Path $folder.FullName "metadata.yaml"
        
        if (Test-Path $metadataPath) {
            try {
                Write-Host "  Loading: $($folder.Name)..." -ForegroundColor Gray -NoNewline
                $content = Get-Content $metadataPath -Raw -Encoding UTF8
                $metadata = ConvertFrom-SimpleYaml $content
                $metadata['Folder'] = $folder.Name
                # Set Enabled to true by default (mod is in Mods folder, not Mods_Disabled)
                $metadata['Enabled'] = $true
                $mods += $metadata
                Write-Host " [OK]" -ForegroundColor Green
            }
            catch {
                Write-Host " [FAILED]" -ForegroundColor Red
                Write-Host "    Error: $_" -ForegroundColor Yellow
            }
        }
        else {
            Write-Host "  Skipping: $($folder.Name) (no metadata.yaml)" -ForegroundColor DarkGray
        }
    }
    
    Write-Host "Successfully loaded $($mods.Count) mod(s)" -ForegroundColor Green
    Write-Host ""
    return $mods
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
        Write-Host "  Loading UI config from ui-config.ps1 for: $($Mod['Name'])" -ForegroundColor Cyan
        try {
            # Execute the ui-config.ps1 script with current configuration
            $result = & $uiConfigPath -CurrentConfig $CurrentConfig
            
            # Handle different return formats
            $parameters = $null
            if ($result -is [array]) {
                # Direct array of parameters
                $parameters = $result
            }
            elseif ($result -is [hashtable] -and $result.ContainsKey('Parameters')) {
                # Hashtable with Parameters key (new format)
                $parameters = $result['Parameters']
            }
            else {
                # Unknown format
                $parameters = $result
            }
            
            if ($parameters -and $parameters.Count -gt 0) {
                Write-Host "  Successfully loaded $($parameters.Count) parameters from ui-config.ps1" -ForegroundColor Green
                return $parameters
            }
            else {
                Write-Host "  ui-config.ps1 returned no parameters, falling back to metadata.yaml" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "  [ERROR] Failed to execute ui-config.ps1: $_" -ForegroundColor Red
            Write-Host "  Falling back to metadata.yaml Parameters" -ForegroundColor Yellow
        }
    }
    
    # Fall back to metadata.yaml Parameters section (legacy approach)
    if ($Mod.ContainsKey('Parameters') -and $Mod['Parameters'].Count -gt 0) {
        Write-Host "  Loading parameters from metadata.yaml for: $($Mod['Name'])" -ForegroundColor Gray
        return $Mod['Parameters']
    }
    
    return @()
}

# Settings.json management
function Get-GameSettings {
    if (-not (Test-Path $script:SettingsPath)) {
        Write-Host "[WARN] settings.json not found at: $script:SettingsPath" -ForegroundColor Yellow
        return $null
    }
    
    try {
        Write-Host "Loading settings.json..." -ForegroundColor Cyan
        $content = Get-Content $script:SettingsPath -Raw -Encoding UTF8
        $settings = $content | ConvertFrom-Json
        
        # Extract cmd_alias as hashtable
        if ($settings.cmd_alias) {
            $script:CmdAliases = @{}
            $settings.cmd_alias.PSObject.Properties | ForEach-Object {
                $script:CmdAliases[$_.Name] = $_.Value
            }
            Write-Host "  Loaded $($script:CmdAliases.Count) cmd_alias(es)" -ForegroundColor Green
        }
        
        return $settings
    }
    catch {
        Write-Host "[ERROR] Failed to load settings.json: $_" -ForegroundColor Red
        return $null
    }
}

function Save-GameSettings {
    param($Settings)
    
    try {
        Write-Host "Saving settings.json..." -ForegroundColor Cyan
        
        # Convert hashtable back to PSObject for cmd_alias
        if ($script:CmdAliases) {
            $cmdAliasObj = New-Object PSObject
            $script:CmdAliases.GetEnumerator() | Sort-Object Key | ForEach-Object {
                $cmdAliasObj | Add-Member -MemberType NoteProperty -Name $_.Key -Value $_.Value
            }
            $Settings.cmd_alias = $cmdAliasObj
        }
        
        # Ensure directory exists
        $settingsDir = Split-Path $script:SettingsPath -Parent
        if (-not (Test-Path $settingsDir)) {
            New-Item -Path $settingsDir -ItemType Directory -Force | Out-Null
        }
        
        # Save with proper formatting
        $json = $Settings | ConvertTo-Json -Depth 10
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($script:SettingsPath, $json, $utf8NoBom)
        
        Write-Host "  [OK] Saved settings.json" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "[ERROR] Failed to save settings.json: $_" -ForegroundColor Red
        return $false
    }
}

# Configuration management
function Get-ModConfig {
    param($ModId)
    
    $entryPath = Join-Path $script:ModsDirectory "$ModId\entry.lua"
    
    if (-not (Test-Path $entryPath)) {
        Write-Host "  [WARN] entry.lua not found for $ModId" -ForegroundColor Yellow
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
        Write-Host "  [WARN] Failed to parse config for $ModId : $_" -ForegroundColor Yellow
        return @{}
    }
}

function Save-ModConfig {
    param($ModId, $Config)
    
    try {
        $entryPath = Join-Path $script:ModsDirectory "$ModId\entry.lua"
        
        if (-not (Test-Path $entryPath)) {
            Write-Host "  [ERROR] entry.lua not found for $ModId" -ForegroundColor Red
            return $false
        }
        
        # Read the current file
        $content = Get-Content $entryPath -Raw
        
        # Find the config section and split into three parts: before, config section, after
        # This regex captures:
        # Group 1: Everything before and including "local config = {"
        # Group 2: The config content (to be replaced)
        # Group 3: Everything from "}" through the end of the file
        if ($content -match '(?s)(.*?-- ===== MOD CONFIGURATION START =====.*?local config = \{)(.*?)(\}.*?-- ===== MOD CONFIGURATION END =====.*)') {
            $beforeConfig = $Matches[1]
            $afterConfigAndRest = $Matches[3]
            
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
            
            # Reconstruct the entire file: before + new config + after
            $newContent = $beforeConfig + $newConfigBlock + $afterConfigAndRest
            
            # Write back to file with UTF-8 without BOM
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($entryPath, $newContent, $utf8NoBom)
            
            Write-Host "  [OK] Saved config for $ModId" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "  [ERROR] Could not find config section in entry.lua for $ModId" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "  [ERROR] Failed to save config for $ModId : $_" -ForegroundColor Red
        Write-Host "  Details: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Alias management UI functions
function Update-AliasList {
    param($ListBox)
    
    try {
        Write-Host "Updating alias list..." -ForegroundColor Cyan
        $ListBox.Items.Clear()
        
        $sortedAliases = $script:CmdAliases.GetEnumerator() | Sort-Object Key
        
        foreach ($alias in $sortedAliases) {
            $item = New-Object System.Windows.Controls.ListBoxItem
            
            $stackPanel = New-Object System.Windows.Controls.StackPanel
            
            $nameText = New-Object System.Windows.Controls.TextBlock
            $nameText.Text = $alias.Key
            $nameText.FontWeight = "Bold"
            $nameText.FontFamily = "Consolas"
            $stackPanel.Children.Add($nameText) | Out-Null
            
            $commandPreview = $alias.Value
            if ($commandPreview.Length -gt 50) {
                $commandPreview = $commandPreview.Substring(0, 47) + "..."
            }
            
            $previewText = New-Object System.Windows.Controls.TextBlock
            $previewText.Text = $commandPreview
            $previewText.FontSize = 10
            $previewText.Foreground = "#FF666666"
            $previewText.FontFamily = "Consolas"
            $previewText.TextWrapping = "Wrap"
            $stackPanel.Children.Add($previewText) | Out-Null
            
            $item.Content = $stackPanel
            $item.Tag = @{ Name = $alias.Key; Command = $alias.Value }
            $item.Margin = "0,2,0,2"
            
            $ListBox.Items.Add($item) | Out-Null
        }
        
        Write-Host "Alias list updated with $($script:CmdAliases.Count) alias(es)" -ForegroundColor Green
    }
    catch {
        Write-Host "[ERROR] Update-AliasList: $_" -ForegroundColor Red
        Write-Host $_.ScriptStackTrace -ForegroundColor Yellow
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
    
    Update-AliasPreview
}

function Hide-AliasEditor {
    $window.FindName("AliasEmptyState").Visibility = "Visible"
    $window.FindName("AliasEditorPanel").Visibility = "Collapsed"
    $window.FindName("AliasNameBox").Text = ""
    $window.FindName("AliasCommandBox").Text = ""
    $window.FindName("AliasPreviewText").Text = ""
}

function Update-AliasPreview {
    $aliasName = $window.FindName("AliasNameBox").Text
    $command = $window.FindName("AliasCommandBox").Text
    
    if ([string]::IsNullOrWhiteSpace($aliasName)) {
        $window.FindName("AliasPreviewText").Text = "Enter an alias name to see preview"
        return
    }
    
    if ([string]::IsNullOrWhiteSpace($command)) {
        $window.FindName("AliasPreviewText").Text = "Enter a command to see preview"
        return
    }
    
    $preview = "Usage: $aliasName`n`nExpands to:`n$command"
    $window.FindName("AliasPreviewText").Text = $preview
}

# Get-InstalledMods - Scan for mods in lua/ directory
function Set-ModEnabled {
    param(
        [string]$ModFolder,
        [bool]$Enabled
    )
    
    try {
        Write-Host "Set-ModEnabled called for: $ModFolder, Enabled: $Enabled" -ForegroundColor Cyan
        
        # Ensure directories exist before any operations
        if (-not (Test-Path $script:ModsDirectory)) {
            Write-Host "Creating Mods directory: $script:ModsDirectory" -ForegroundColor Yellow
            New-Item -Path $script:ModsDirectory -ItemType Directory -Force | Out-Null
        }
        
        if (-not (Test-Path $script:DisabledModsDirectory)) {
            Write-Host "Creating Disabled Mods directory: $script:DisabledModsDirectory" -ForegroundColor Yellow
            New-Item -Path $script:DisabledModsDirectory -ItemType Directory -Force | Out-Null
        }
        
        $enabledPath = Join-Path $script:ModsDirectory $ModFolder
        $disabledPath = Join-Path $script:DisabledModsDirectory $ModFolder
        
        Write-Host "  Enabled path: $enabledPath (exists: $(Test-Path $enabledPath))" -ForegroundColor Gray
        Write-Host "  Disabled path: $disabledPath (exists: $(Test-Path $disabledPath))" -ForegroundColor Gray
        
        if ($Enabled) {
            # Move from disabled to enabled
            if (Test-Path $disabledPath) {
                Write-Host "Moving from disabled to enabled..." -ForegroundColor Cyan
                Move-Item -Path $disabledPath -Destination $enabledPath -Force -ErrorAction Stop
                Write-Host "  Successfully moved to: $enabledPath" -ForegroundColor Green
                return $true
            }
            else {
                Write-Host "  Disabled path doesn't exist, mod may already be enabled" -ForegroundColor Gray
                return $false
            }
        }
        else {
            # Move from enabled to disabled
            if (Test-Path $enabledPath) {
                Write-Host "Moving from enabled to disabled..." -ForegroundColor Cyan
                Move-Item -Path $enabledPath -Destination $disabledPath -Force -ErrorAction Stop
                Write-Host "  Successfully moved to: $disabledPath" -ForegroundColor Green
                return $true
            }
            else {
                Write-Host "  Enabled path doesn't exist, mod may already be disabled" -ForegroundColor Gray
                return $false
            }
        }
    }
    catch {
        Write-Host "[ERROR] Set-ModEnabled failed: $_" -ForegroundColor Red
        Write-Host $_.ScriptStackTrace -ForegroundColor Yellow
        return $false
    }
}

# UI Update functions
function Update-ModList {
    param($ListBox)
    
    try {
        Write-Host "Updating mod list..." -ForegroundColor Cyan
        
        # Only rebuild on first load (empty list)
        if ($ListBox.Items.Count -eq 0) {
            Write-Host "Building mod list (first time)..." -ForegroundColor Gray
            foreach ($mod in $script:Mods) {
                # Skip modloader - it's hidden infrastructure
                if ($mod['ID'] -eq 'modloader') {
                    Write-Host "Skipping modloader from display (always enabled)" -ForegroundColor Gray
                    continue
                }
                
                $item = New-ModListItem $mod
                $ListBox.Items.Add($item) | Out-Null
            }
        }
        
        Write-Host "Mod list updated" -ForegroundColor Green
    }
    catch {
        Write-Host "[ERROR] Update-ModList: $_" -ForegroundColor Red
        Write-Host $_.ScriptStackTrace -ForegroundColor Yellow
    }
}

# Create a new mod list item (called only once per mod)
function New-ModListItem {
    param($mod)
    
    $enabled = $mod['Enabled']
    
    # Create colored border for list item
    $border = New-Object System.Windows.Controls.Border
    $border.Margin = "0,2,0,2"
    $border.Padding = "5"
    $border.BorderThickness = "2,0,0,0"
    $border.BorderBrush = Get-ModStatusColor $mod['Development Status'] $enabled
    
    $grid = New-Object System.Windows.Controls.Grid
    $grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{ Width = "Auto" }))
    $grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{ Width = "*" }))
    
    $checkbox = New-Object System.Windows.Controls.CheckBox
    $checkbox.IsChecked = $enabled
    $checkbox.VerticalAlignment = "Center"
    $checkbox.Margin = "0,0,10,0"
    $checkbox.Tag = $mod
    
    # Add checkbox event handlers - simplified to avoid blocking
    $checkbox.Add_Checked({
            param($sender, $e)
            try {
                $modData = $sender.Tag
                Write-Host "Toggling enabled: $($modData['Name'])" -ForegroundColor Cyan
            
                # Just set the enabled flag and perform the operation
                Set-ModEnabled $modData['Folder'] $true | Out-Null
                Write-Host "Successfully enabled" -ForegroundColor Green
            }
            catch {
                Write-Host "[ERROR] Checkbox checked: $_" -ForegroundColor Red
            }
        })
    
    $checkbox.Add_Unchecked({
            param($sender, $e)
            try {
                $modData = $sender.Tag
                Write-Host "Toggling disabled: $($modData['Name'])" -ForegroundColor Cyan
            
                # Just set the disabled flag and perform the operation
                Set-ModEnabled $modData['Folder'] $false | Out-Null
                Write-Host "Successfully disabled" -ForegroundColor Green
            }
            catch {
                Write-Host "[ERROR] Checkbox unchecked: $_" -ForegroundColor Red
            }
        })
    
    [System.Windows.Controls.Grid]::SetColumn($checkbox, 0)
    $grid.Children.Add($checkbox) | Out-Null
    
    $stackPanel = New-Object System.Windows.Controls.StackPanel
    
    $nameText = New-Object System.Windows.Controls.TextBlock
    $nameText.Text = $mod['Name']
    $nameText.FontWeight = "Bold"
    $nameText.TextWrapping = "Wrap"
    $stackPanel.Children.Add($nameText) | Out-Null
    
    $idText = New-Object System.Windows.Controls.TextBlock
    $idText.Text = "$($mod['ID']) - $($mod['Development Status'])"
    $idText.FontSize = 10
    $idText.Foreground = Get-ModStatusColor $mod['Development Status'] $enabled
    $stackPanel.Children.Add($idText) | Out-Null
    
    [System.Windows.Controls.Grid]::SetColumn($stackPanel, 1)
    $grid.Children.Add($stackPanel) | Out-Null
    
    $border.Child = $grid
    
    $item = New-Object System.Windows.Controls.ListBoxItem
    $item.Content = $border
    $item.Tag = $mod
    $item.Background = "Transparent"
    $item.BorderThickness = 0
    
    return $item
}

function Refresh-ModParameters {
    # Refresh the parameter list for the current mod
    # This is called when a parameter value changes to support dynamic/conditional UIs
    if ($script:CurrentMod) {
        Write-Host "Refreshing parameters for: $($script:CurrentMod['Name'])" -ForegroundColor Cyan
        Update-ModDetails $script:CurrentMod
    }
}

function Update-ModDetails {
    param($Mod)
    
    try {
        if (-not $Mod) {
            Write-Host "[ERROR] Update-ModDetails: Mod is null" -ForegroundColor Red
            return
        }
        
        Write-Host "Loading details for: $($Mod['Name'])" -ForegroundColor Cyan
        $script:CurrentMod = $Mod
        
        $window.FindName("EmptyStatePanel").Visibility = "Collapsed"
        $window.FindName("ModInfoPanel").Visibility = "Visible"
        $window.FindName("DescriptionExpander").Visibility = "Visible"
        $window.FindName("ParametersPanel").Visibility = "Visible"
        $window.FindName("ActionButtonsPanel").Visibility = "Visible"
        
        $window.FindName("ModNameText").Text = $Mod['Name']
        $window.FindName("ModAuthorText").Text = $Mod['Author']
        $window.FindName("ModStatusText").Text = $Mod['Development Status']
        $window.FindName("ModStatusText").Foreground = Get-ModStatusColor $Mod['Development Status'] $Mod['Enabled']
        $window.FindName("ModVersionText").Text = $Mod['Last Updated']
        $window.FindName("ModGameVersionText").Text = $Mod['Game Version Supported']
        
        # Render description - use simple text for now to avoid blocking
        if ($Mod['Description']) {
            $tb = New-Object System.Windows.Controls.TextBlock
            $tb.Text = $Mod['Description']
            $tb.TextWrapping = "Wrap"
            $window.FindName("ModDescriptionText").Content = $tb
        }
    
        # Clear and rebuild parameters
        $paramPanel = $window.FindName("ParametersList")
        if (-not $paramPanel) {
            Write-Host "[ERROR] ParametersList control not found in XAML. Check XAML definition." -ForegroundColor Red
            Write-Host "Available controls in ParametersPanel:" -ForegroundColor Yellow
            $parentPanel = $window.FindName("ParametersPanel")
            if ($parentPanel) {
                $parentPanel.Children | ForEach-Object { Write-Host "  - $($_.GetType().Name): $($_.Name)" -ForegroundColor Gray }
            }
            return
        }
        $paramPanel.Children.Clear()
    
        # Load config from entry.lua only if not already in memory
        if (-not $script:Config.mod_parameters.ContainsKey($Mod['ID'])) {
            Write-Host "  Loading initial config from entry.lua for: $($Mod['Name'])" -ForegroundColor Gray
            $currentModConfig = Get-ModConfig $Mod['ID']
            $script:Config.mod_parameters[$Mod['ID']] = $currentModConfig
        }
        else {
            Write-Host "  Using cached config for: $($Mod['Name'])" -ForegroundColor Gray
        }
        
        # Get the current config (either just loaded or from cache)
        $currentModConfig = if ($script:Config.mod_parameters.ContainsKey($Mod['ID'])) {
            $script:Config.mod_parameters[$Mod['ID']]
        }
        else {
            @{}
        }
    
        # Load parameters using new Get-ModParameters function
        $parameters = Get-ModParameters -Mod $Mod -CurrentConfig $currentModConfig
    
        if ($parameters -and $parameters.Count -gt 0) {
            foreach ($param in $parameters) {
                # Skip invalid parameters
                if (-not $param) {
                    continue
                }
                
                # Handle special parameter types (section, info, warning)
                if ($param.ContainsKey('Type')) {
                    if ($param['Type'] -eq 'section') {
                        # Render section header
                        $section = New-Object System.Windows.Controls.StackPanel
                        $section.Margin = "0,15,0,5"
                    
                        $sectionLabel = New-Object System.Windows.Controls.TextBlock
                        $sectionLabel.Text = $param['Label']
                        $sectionLabel.FontSize = 14
                        $sectionLabel.FontWeight = "Bold"
                        $section.Children.Add($sectionLabel) | Out-Null
                    
                        if ($param.ContainsKey('Description')) {
                            $sectionDesc = New-Object System.Windows.Controls.TextBlock
                            $sectionDesc.Text = $param['Description']
                            $sectionDesc.FontSize = 11
                            $sectionDesc.Margin = "0,2,0,0"
                            $section.Children.Add($sectionDesc) | Out-Null
                        }
                    
                        $paramPanel.Children.Add($section) | Out-Null
                        continue
                    }
                    elseif ($param['Type'] -eq 'info') {
                        # Render info message
                        $infoBorder = New-Object System.Windows.Controls.Border
                        $infoBorder.Background = "#E3F2FD"
                        $infoBorder.BorderBrush = "#2196F3"
                        $infoBorder.BorderThickness = "2"
                        $infoBorder.Padding = "10"
                        $infoBorder.Margin = "0,5,0,5"
                    
                        $infoText = New-Object System.Windows.Controls.TextBlock
                        # Support both 'Text' and 'Message' keys
                        $message = if ($param.ContainsKey('Text')) { $param['Text'] } elseif ($param.ContainsKey('Message')) { $param['Message'] } else { "" }
                        $infoText.Text = $message
                        $infoText.TextWrapping = "Wrap"
                        $infoBorder.Child = $infoText
                    
                        $paramPanel.Children.Add($infoBorder) | Out-Null
                        continue
                    }
                    elseif ($param['Type'] -eq 'warning') {
                        # Render warning message
                        $warnBorder = New-Object System.Windows.Controls.Border
                        $warnBorder.Background = "#FFF3E0"
                        $warnBorder.BorderBrush = "#FF9800"
                        $warnBorder.BorderThickness = "2"
                        $warnBorder.Padding = "10"
                        $warnBorder.Margin = "0,5,0,5"
                    
                        $warnText = New-Object System.Windows.Controls.TextBlock
                        # Support both 'Text' and 'Message' keys
                        $message = if ($param.ContainsKey('Text')) { $param['Text'] } elseif ($param.ContainsKey('Message')) { $param['Message'] } else { "" }
                        $warnText.Text = $message
                        $warnText.TextWrapping = "Wrap"
                        $warnText.Foreground = "#E65100"
                        $warnBorder.Child = $warnText
                    
                        $paramPanel.Children.Add($warnBorder) | Out-Null
                        continue
                    }
                }
            
                # Skip if parameter is explicitly marked as not visible
                if ($param.ContainsKey('Visible') -and -not $param['Visible']) {
                    continue
                }
                
                # Skip if parameter has no Name (special types like section/info/warning should have been handled above)
                if (-not $param.ContainsKey('Name') -or [string]::IsNullOrEmpty($param['Name'])) {
                    continue
                }
            
                # Get current value
                $currentValue = $param['Default']
                if ($currentModConfig -and $currentModConfig.ContainsKey($param['Name'])) {
                    $currentValue = $currentModConfig[$param['Name']]
                }
            
                $control = New-ParameterControl $Mod['ID'] $param $currentValue
                $paramPanel.Children.Add($control) | Out-Null
            }
        }
        else {
            $tb = New-Object System.Windows.Controls.TextBlock
            $tb.Text = "No configurable parameters"
            $tb.Margin = "10"
            $paramPanel.Children.Add($tb) | Out-Null
        }
    
        Write-Host "Loaded details for: $($Mod['Name'])" -ForegroundColor Green
    }
    catch {
        Write-Host "[ERROR] Update-ModDetails: $_" -ForegroundColor Red
        Write-Host $_.ScriptStackTrace -ForegroundColor Yellow
        [System.Windows.MessageBox]::Show(
            "Error loading mod details: $_",
            "Error",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        )
    }
}

function New-ParameterControl {
    param($ModId, $Param, $CurrentValue)
    
    $border = New-Object System.Windows.Controls.Border
    $border.BorderThickness = "1"
    $border.Padding = "10"
    $border.Margin = "0,0,0,10"
    
    $stack = New-Object System.Windows.Controls.StackPanel
    
    # Label
    $label = New-Object System.Windows.Controls.TextBlock
    $label.Text = $Param['Label']
    $label.FontWeight = "Bold"
    $label.Margin = "0,0,0,5"
    $stack.Children.Add($label) | Out-Null
    
    # Description
    if ($Param.ContainsKey('Description')) {
        $desc = New-Object System.Windows.Controls.TextBlock
        $desc.Text = $Param['Description']
        $desc.FontSize = 11
        $desc.TextWrapping = "Wrap"
        $desc.Margin = "0,0,0,5"
        $stack.Children.Add($desc) | Out-Null
    }
    
    # Input control based on type
    $control = $null
    
    switch ($Param['Type']) {
        'boolean' {
            $control = New-Object System.Windows.Controls.CheckBox
            $control.IsChecked = $CurrentValue
            $control.Content = "Enabled"
            $control.Tag = @{ ModId = $ModId; ParamName = $Param['Name']; Type = 'boolean' }
            $control.Add_Checked({
                    $tag = $this.Tag
                    if (-not $script:Config.mod_parameters.ContainsKey($tag.ModId)) {
                        $script:Config.mod_parameters[$tag.ModId] = @{}
                    }
                    $script:Config.mod_parameters[$tag.ModId][$tag.ParamName] = $true
                    # Refresh parameters if ui-config.ps1 exists (for dynamic UI)
                    Refresh-ModParameters
                })
            $control.Add_Unchecked({
                    $tag = $this.Tag
                    if (-not $script:Config.mod_parameters.ContainsKey($tag.ModId)) {
                        $script:Config.mod_parameters[$tag.ModId] = @{}
                    }
                    $script:Config.mod_parameters[$tag.ModId][$tag.ParamName] = $false
                    # Refresh parameters if ui-config.ps1 exists (for dynamic UI)
                    Refresh-ModParameters
                })
        }
        
        'select' {
            $control = New-Object System.Windows.Controls.ComboBox
            $control.IsEditable = $false
            
            foreach ($option in $Param['Options']) {
                $control.Items.Add($option) | Out-Null
            }
            $control.SelectedItem = $CurrentValue
            $control.Tag = @{ ModId = $ModId; ParamName = $Param['Name']; Type = 'select' }
            $control.Add_SelectionChanged({
                    if ($this.SelectedItem) {
                        $tag = $this.Tag
                        if (-not $script:Config.mod_parameters.ContainsKey($tag.ModId)) {
                            $script:Config.mod_parameters[$tag.ModId] = @{}
                        }
                        $script:Config.mod_parameters[$tag.ModId][$tag.ParamName] = $this.SelectedItem
                        # Refresh parameters if ui-config.ps1 exists (for dynamic UI)
                        Refresh-ModParameters
                    }
                })
        }
        
        'integer' {
            $grid = New-Object System.Windows.Controls.Grid
            $col1 = New-Object System.Windows.Controls.ColumnDefinition
            $col1.Width = "*"
            $col2 = New-Object System.Windows.Controls.ColumnDefinition
            $col2.Width = "Auto"
            $grid.ColumnDefinitions.Add($col1) | Out-Null
            $grid.ColumnDefinitions.Add($col2) | Out-Null
            
            $textbox = New-Object System.Windows.Controls.TextBox
            $textbox.Text = $CurrentValue.ToString()
            $textbox.Tag = @{ ModId = $ModId; ParamName = $Param['Name']; Type = 'integer'; Min = $Param['Min']; Max = $Param['Max'] }
            $textbox.Add_TextChanged({
                    $tag = $this.Tag
                    $value = 0
                    if ([int]::TryParse($this.Text, [ref]$value)) {
                        if ($tag.ContainsKey('Min') -and $value -lt $tag.Min) {
                            return
                        }
                        if ($tag.ContainsKey('Max') -and $value -gt $tag.Max) {
                            return
                        }
                        if (-not $script:Config.mod_parameters.ContainsKey($tag.ModId)) {
                            $script:Config.mod_parameters[$tag.ModId] = @{}
                        }
                        $script:Config.mod_parameters[$tag.ModId][$tag.ParamName] = $value
                    }
                })
            [System.Windows.Controls.Grid]::SetColumn($textbox, 0)
            $grid.Children.Add($textbox) | Out-Null
            
            if ($Param.ContainsKey('Min') -and $Param.ContainsKey('Max')) {
                $info = New-Object System.Windows.Controls.TextBlock
                $info.Text = "($($Param['Min'])-$($Param['Max']))"
                $info.Margin = "5,0,0,0"
                $info.VerticalAlignment = "Center"
                [System.Windows.Controls.Grid]::SetColumn($info, 1)
                $grid.Children.Add($info) | Out-Null
            }
            
            $control = $grid
        }
        
        'number' {
            $grid = New-Object System.Windows.Controls.Grid
            $col1 = New-Object System.Windows.Controls.ColumnDefinition
            $col1.Width = "*"
            $col2 = New-Object System.Windows.Controls.ColumnDefinition
            $col2.Width = "Auto"
            $grid.ColumnDefinitions.Add($col1) | Out-Null
            $grid.ColumnDefinitions.Add($col2) | Out-Null
            
            $textbox = New-Object System.Windows.Controls.TextBox
            $textbox.Text = $CurrentValue.ToString()
            $textbox.Tag = @{ ModId = $ModId; ParamName = $Param['Name']; Type = 'number'; Min = $Param['Min']; Max = $Param['Max'] }
            $textbox.Add_TextChanged({
                    $tag = $this.Tag
                    $value = 0.0
                    if ([double]::TryParse($this.Text, [ref]$value)) {
                        if ($tag.ContainsKey('Min') -and $value -lt $tag.Min) {
                            return
                        }
                        if ($tag.ContainsKey('Max') -and $value -gt $tag.Max) {
                            return
                        }
                        if (-not $script:Config.mod_parameters.ContainsKey($tag.ModId)) {
                            $script:Config.mod_parameters[$tag.ModId] = @{}
                        }
                        $script:Config.mod_parameters[$tag.ModId][$tag.ParamName] = $value
                    }
                })
            [System.Windows.Controls.Grid]::SetColumn($textbox, 0)
            $grid.Children.Add($textbox) | Out-Null
            
            if ($Param.ContainsKey('Min') -and $Param.ContainsKey('Max')) {
                $info = New-Object System.Windows.Controls.TextBlock
                $info.Text = "($($Param['Min'])-$($Param['Max']))"
                $info.Margin = "5,0,0,0"
                $info.VerticalAlignment = "Center"
                [System.Windows.Controls.Grid]::SetColumn($info, 1)
                $grid.Children.Add($info) | Out-Null
            }
            
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

# Main execution
try {
    # Load XAML
    $reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xaml))
    $window = [System.Windows.Markup.XamlReader]::Load($reader)
    
    # Load data
    $script:Mods = Get-InstalledMods
    # Initialize config structure for all mods
    $script:Config = @{
        mod_parameters = @{}
    }
    $script:Settings = Get-GameSettings
    
    # Get controls - Mods tab
    $modListBox = $window.FindName("ModListBox")
    $enableAllButton = $window.FindName("EnableAllButton")
    $disableAllButton = $window.FindName("DisableAllButton")
    $refreshButton = $window.FindName("RefreshButton")
    $launchGameButton = $window.FindName("LaunchGameButton")
    $saveButton = $window.FindName("SaveButton")
    $saveAllButton = $window.FindName("SaveAllButton")
    $resetModButton = $window.FindName("ResetModButton")
    $resetAllButton = $window.FindName("ResetAllButton")
    $exitButton = $window.FindName("ExitButton")
    
    # Get controls - Aliases tab
    $aliasListBox = $window.FindName("AliasListBox")
    $addAliasButton = $window.FindName("AddAliasButton")
    $deleteAliasButton = $window.FindName("DeleteAliasButton")
    $saveAliasesButton = $window.FindName("SaveAliasesButton")
    $aliasNameBox = $window.FindName("AliasNameBox")
    $aliasCommandBox = $window.FindName("AliasCommandBox")
    $cancelAliasButton = $window.FindName("CancelAliasButton")
    $applyAliasButton = $window.FindName("ApplyAliasButton")
    
    # Populate mod list
    Update-ModList $modListBox
    
    # Populate alias list
    if ($script:Settings) {
        Update-AliasList $aliasListBox
    }
    
    # Update status text
    $window.FindName("StatusText").Text = "$($script:Mods.Count) mod(s) loaded - Ready"
    
    # Event handlers
    $modListBox.Add_SelectionChanged({
            try {
                if ($this.SelectedItem) {
                    $item = $this.SelectedItem
                    Write-Host "Selected mod: $($item.Tag['Name'])" -ForegroundColor Cyan
                    Update-ModDetails $item.Tag
                }
            }
            catch {
                Write-Host "[ERROR] SelectionChanged handler: $_" -ForegroundColor Red
                Write-Host $_.ScriptStackTrace -ForegroundColor Yellow
                [System.Windows.MessageBox]::Show(
                    "Error loading mod details: $_",
                    "Error",
                    [System.Windows.MessageBoxButton]::OK,
                    [System.Windows.MessageBoxImage]::Error
                )
            }
        })
    
    $enableAllButton.Add_Click({
            try {
                Write-Host "Enabling all mods..." -ForegroundColor Cyan
                foreach ($item in $modListBox.Items) {
                    $modData = $item.Content.Child.Children[1].Children[0].DataContext
                    if ($modData -and $modData['ID'] -ne 'modloader') {
                        Set-ModEnabled $modData['Folder'] $true
                    }
                }
                $script:Mods = Get-InstalledMods
                Update-ModList $modListBox
                Write-Host "All mods enabled" -ForegroundColor Green
            }
            catch {
                Write-Host "[ERROR] Enable all handler: $_" -ForegroundColor Red
                Write-Host $_.ScriptStackTrace -ForegroundColor Yellow
                [System.Windows.MessageBox]::Show(
                    "Error enabling mods: $_",
                    "Error",
                    [System.Windows.MessageBoxButton]::OK,
                    [System.Windows.MessageBoxImage]::Error
                )
            }
        })
    
    $disableAllButton.Add_Click({
            try {
                Write-Host "Disabling all mods..." -ForegroundColor Cyan
                foreach ($item in $modListBox.Items) {
                    $modData = $item.Content.Child.Children[1].Children[0].DataContext
                    if ($modData -and $modData['ID'] -ne 'modloader') {
                        Set-ModEnabled $modData['Folder'] $false
                    }
                }
                $script:Mods = Get-InstalledMods
                Update-ModList $modListBox
                Write-Host "All mods disabled" -ForegroundColor Green
            }
            catch {
                Write-Host "[ERROR] Disable all handler: $_" -ForegroundColor Red
                Write-Host $_.ScriptStackTrace -ForegroundColor Yellow
                [System.Windows.MessageBox]::Show(
                    "Error disabling mods: $_",
                    "Error",
                    [System.Windows.MessageBoxButton]::OK,
                    [System.Windows.MessageBoxImage]::Error
                )
            }
        })
    
    $refreshButton.Add_Click({
            try {
                Write-Host "Refreshing mod list..." -ForegroundColor Cyan
                $script:Mods = Get-InstalledMods
                Update-ModList $modListBox
                Write-Host "Mod list refreshed" -ForegroundColor Green
            }
            catch {
                Write-Host "[ERROR] Refresh handler: $_" -ForegroundColor Red
                Write-Host $_.ScriptStackTrace -ForegroundColor Yellow
                [System.Windows.MessageBox]::Show(
                    "Error refreshing mods: $_",
                    "Error",
                    [System.Windows.MessageBoxButton]::OK,
                    [System.Windows.MessageBoxImage]::Error
                )
            }
        })
    
    $launchGameButton.Add_Click({
            Write-Host "Launching game via Steam..." -ForegroundColor Cyan
            Start-Process "steam://rungameid/2939600"
            Start-Sleep -Milliseconds 500
            $window.Close()
        })
    
    $saveButton.Add_Click({
            if ($script:CurrentMod) {
                $modId = $script:CurrentMod['ID']
                if ($script:Config.mod_parameters.ContainsKey($modId)) {
                    if (Save-ModConfig $modId $script:Config.mod_parameters[$modId]) {
                        [System.Windows.MessageBox]::Show(
                            "Configuration saved successfully for $($script:CurrentMod['Name'])!",
                            "Success",
                            [System.Windows.MessageBoxButton]::OK,
                            [System.Windows.MessageBoxImage]::Information
                        )
                    }
                    else {
                        [System.Windows.MessageBox]::Show(
                            "Failed to save configuration. Check console for details.",
                            "Error",
                            [System.Windows.MessageBoxButton]::OK,
                            [System.Windows.MessageBoxImage]::Error
                        )
                    }
                }
                else {
                    [System.Windows.MessageBox]::Show(
                        "No configuration changes to save for this mod.",
                        "Info",
                        [System.Windows.MessageBoxButton]::OK,
                        [System.Windows.MessageBoxImage]::Information
                    )
                }
            }
            else {
                [System.Windows.MessageBox]::Show(
                    "Please select a mod first.",
                    "No Mod Selected",
                    [System.Windows.MessageBoxButton]::OK,
                    [System.Windows.MessageBoxImage]::Warning
                )
            }
        })
    
    $saveAllButton.Add_Click({
            $savedCount = 0
            $errorCount = 0
            
            foreach ($modId in $script:Config.mod_parameters.Keys) {
                Write-Host "Saving config for: $modId" -ForegroundColor Cyan
                if (Save-ModConfig $modId $script:Config.mod_parameters[$modId]) {
                    $savedCount++
                }
                else {
                    $errorCount++
                }
            }
            
            if ($savedCount -gt 0 -or $errorCount -eq 0) {
                $message = "Saved configuration for $savedCount mod(s)"
                if ($errorCount -gt 0) {
                    $message += "`n$errorCount mod(s) failed to save. Check console for details."
                }
                [System.Windows.MessageBox]::Show(
                    $message,
                    "Save Complete",
                    [System.Windows.MessageBoxButton]::OK,
                    [System.Windows.MessageBoxImage]::Information
                )
            }
            else {
                [System.Windows.MessageBox]::Show(
                    "No configuration changes to save.",
                    "Info",
                    [System.Windows.MessageBoxButton]::OK,
                    [System.Windows.MessageBoxImage]::Information
                )
            }
        })
    
    $resetModButton.Add_Click({
            if ($script:CurrentMod) {
                $result = [System.Windows.MessageBox]::Show(
                    "Reset all parameters for $($script:CurrentMod['Name']) to defaults?",
                    "Confirm Reset",
                    [System.Windows.MessageBoxButton]::YesNo,
                    [System.Windows.MessageBoxImage]::Question
                )
            
                if ($result -eq 'Yes') {
                    if ($script:Config.mod_parameters.ContainsKey($script:CurrentMod['ID'])) {
                        $script:Config.mod_parameters.Remove($script:CurrentMod['ID'])
                    }
                    Update-ModDetails $script:CurrentMod
                }
            }
        })
    
    $resetAllButton.Add_Click({
            $result = [System.Windows.MessageBox]::Show(
                "Reset ALL mod configurations to defaults? This cannot be undone!",
                "Confirm Reset All",
                [System.Windows.MessageBoxButton]::YesNo,
                [System.Windows.MessageBoxImage]::Warning
            )
        
            if ($result -eq 'Yes') {
                $script:Config.enabled_mods = @{}
                $script:Config.mod_parameters = @{}
                Save-ModConfig $script:Config
                Update-ModList $modListBox
                $window.FindName("EmptyStatePanel").Visibility = "Visible"
                $window.FindName("ModInfoPanel").Visibility = "Collapsed"
                $window.FindName("DescriptionExpander").Visibility = "Collapsed"
                $window.FindName("ParametersPanel").Visibility = "Collapsed"
                $window.FindName("ActionButtonsPanel").Visibility = "Collapsed"
            }
        })
    
    # Aliases tab event handlers
    $aliasListBox.Add_SelectionChanged({
            try {
                if ($this.SelectedItem) {
                    $aliasData = $this.SelectedItem.Tag
                    Show-AliasEditor -AliasName $aliasData.Name -AliasCommand $aliasData.Command -IsNew $false
                }
            }
            catch {
                Write-Host "[ERROR] Alias selection changed: $_" -ForegroundColor Red
            }
        })
    
    $addAliasButton.Add_Click({
            try {
                Show-AliasEditor -AliasName "" -AliasCommand "" -IsNew $true
                $aliasListBox.SelectedItem = $null
            }
            catch {
                Write-Host "[ERROR] Add alias: $_" -ForegroundColor Red
            }
        })
    
    $deleteAliasButton.Add_Click({
            try {
                if ($aliasListBox.SelectedItem) {
                    $aliasData = $aliasListBox.SelectedItem.Tag
                    $result = [System.Windows.MessageBox]::Show(
                        "Delete alias '$($aliasData.Name)'?",
                        "Confirm Delete",
                        [System.Windows.MessageBoxButton]::YesNo,
                        [System.Windows.MessageBoxImage]::Question
                    )
                    
                    if ($result -eq 'Yes') {
                        $script:CmdAliases.Remove($aliasData.Name)
                        Update-AliasList $aliasListBox
                        Hide-AliasEditor
                        [System.Windows.MessageBox]::Show(
                            "Alias deleted. Click 'Save Aliases' to persist changes.",
                            "Alias Deleted",
                            [System.Windows.MessageBoxButton]::OK,
                            [System.Windows.MessageBoxImage]::Information
                        )
                    }
                }
                else {
                    [System.Windows.MessageBox]::Show(
                        "Please select an alias to delete.",
                        "No Selection",
                        [System.Windows.MessageBoxButton]::OK,
                        [System.Windows.MessageBoxImage]::Warning
                    )
                }
            }
            catch {
                Write-Host "[ERROR] Delete alias: $_" -ForegroundColor Red
                [System.Windows.MessageBox]::Show(
                    "Error deleting alias: $_",
                    "Error",
                    [System.Windows.MessageBoxButton]::OK,
                    [System.Windows.MessageBoxImage]::Error
                )
            }
        })
    
    $saveAliasesButton.Add_Click({
            try {
                if (Save-GameSettings $script:Settings) {
                    [System.Windows.MessageBox]::Show(
                        "Command aliases saved successfully!",
                        "Success",
                        [System.Windows.MessageBoxButton]::OK,
                        [System.Windows.MessageBoxImage]::Information
                    )
                }
                else {
                    [System.Windows.MessageBox]::Show(
                        "Failed to save aliases. Check console for details.",
                        "Error",
                        [System.Windows.MessageBoxButton]::OK,
                        [System.Windows.MessageBoxImage]::Error
                    )
                }
            }
            catch {
                Write-Host "[ERROR] Save aliases: $_" -ForegroundColor Red
                [System.Windows.MessageBox]::Show(
                    "Error saving aliases: $_",
                    "Error",
                    [System.Windows.MessageBoxButton]::OK,
                    [System.Windows.MessageBoxImage]::Error
                )
            }
        })
    
    $aliasNameBox.Add_TextChanged({
            Update-AliasPreview
        })
    
    $aliasCommandBox.Add_TextChanged({
            Update-AliasPreview
        })
    
    $cancelAliasButton.Add_Click({
            Hide-AliasEditor
            $aliasListBox.SelectedItem = $null
        })
    
    $applyAliasButton.Add_Click({
            try {
                $aliasName = $window.FindName("AliasNameBox").Text.Trim()
                $aliasCommand = $window.FindName("AliasCommandBox").Text.Trim()
                
                if ([string]::IsNullOrWhiteSpace($aliasName)) {
                    [System.Windows.MessageBox]::Show(
                        "Please enter an alias name.",
                        "Validation Error",
                        [System.Windows.MessageBoxButton]::OK,
                        [System.Windows.MessageBoxImage]::Warning
                    )
                    return
                }
                
                if ([string]::IsNullOrWhiteSpace($aliasCommand)) {
                    [System.Windows.MessageBox]::Show(
                        "Please enter a command.",
                        "Validation Error",
                        [System.Windows.MessageBoxButton]::OK,
                        [System.Windows.MessageBoxImage]::Warning
                    )
                    return
                }
                
                # Validate alias name (alphanumeric and underscores only)
                if ($aliasName -notmatch '^[a-zA-Z0-9_]+$') {
                    [System.Windows.MessageBox]::Show(
                        "Alias name can only contain letters, numbers, and underscores.",
                        "Validation Error",
                        [System.Windows.MessageBoxButton]::OK,
                        [System.Windows.MessageBoxImage]::Warning
                    )
                    return
                }
                
                # Add or update the alias
                $script:CmdAliases[$aliasName] = $aliasCommand
                Update-AliasList $aliasListBox
                Hide-AliasEditor
                
                [System.Windows.MessageBox]::Show(
                    "Alias saved. Click 'Save Aliases' to persist changes.",
                    "Alias Updated",
                    [System.Windows.MessageBoxButton]::OK,
                    [System.Windows.MessageBoxImage]::Information
                )
            }
            catch {
                Write-Host "[ERROR] Apply alias: $_" -ForegroundColor Red
                [System.Windows.MessageBox]::Show(
                    "Error applying alias: $_",
                    "Error",
                    [System.Windows.MessageBoxButton]::OK,
                    [System.Windows.MessageBoxImage]::Error
                )
            }
        })
    
    $exitButton.Add_Click({
            $window.Close()
        })
    
    # Show window
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host "Opening GUI window..." -ForegroundColor Cyan
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host ""
    $window.ShowDialog() | Out-Null
}
catch {
    [System.Windows.MessageBox]::Show(
        "Fatal error: $_`n`n$($_.ScriptStackTrace)",
        "Error",
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Error
    )
}
