# Initial GitHub.com connectivity check with 1 second timeout
$canConnectToGitHub = Test-Connection github.com -Count 1 -Quiet -TimeoutSeconds 1

if ($null -ne $env:TERM_PROGRAM -and $env:TERM_PROGRAM -eq 'VSCODE') {
    Write-Host 'VSCODE! Not loading profile.' -ForegroundColor Green
    #Import-Module -Name Terminal-Icons
    #Import-Module -Name dbatools
    return
}

# Ensure Terminal-Icons module is installed before importing
if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
    Install-Module -Name Terminal-Icons -Scope CurrentUser -Force -SkipPublisherCheck
}
Import-Module -Name Terminal-Icons

# Import-Module -Name dbatools
oh-my-posh --init --shell pwsh --config "$env:posh_themes_path\powerlevel10k_rainbow.omp.json" | Invoke-Expression


# Load editor services command suite
# Import-CommandSuite


Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle ListView

if (Test-Path 'E:\scripts\Powershell') {
    Set-Location 'E:\scripts\Powershell'
}

$env:PATH = $env:PATH + ';C:\Program Files\Oracle\VirtualBox'

# Dracula readline configuration. Requires version 2.0, if you have 1.2 convert to `Set-PSReadlineOption -TokenType`
Set-PSReadLineOption -Color @{
    'Command'          = [ConsoleColor]::Green
    'Parameter'        = [ConsoleColor]::Gray
    'Operator'         = [ConsoleColor]::Magenta
    'Variable'         = [ConsoleColor]::White
    'String'           = [ConsoleColor]::Yellow
    'Number'           = [ConsoleColor]::Blue
    'Type'             = [ConsoleColor]::Cyan
    'Comment'          = [ConsoleColor]::DarkCyan
    'InlinePrediction' = '#9FC5E8'
}

function Update-PowerShell {
    if (-not $global:canConnectToGitHub) {
        Write-Host 'Skipping PowerShell update check due to GitHub.com not responding within 1 second.' -ForegroundColor Yellow
        return
    }

    try {
        Write-Host 'Checking for PowerShell updates...' -ForegroundColor Cyan
        $updateNeeded = $false
        $currentVersion = $PSVersionTable.PSVersion.ToString()
        $gitHubApiUrl = 'https://api.github.com/repos/PowerShell/PowerShell/releases/latest'
        $latestReleaseInfo = Invoke-RestMethod -Uri $gitHubApiUrl
        $latestVersion = $latestReleaseInfo.tag_name.Trim('v')
        if ($currentVersion -lt $latestVersion) {
            $updateNeeded = $true
        }

        if ($updateNeeded) {
            Write-Host 'Updating PowerShell...' -ForegroundColor Yellow
            winget upgrade 'Microsoft.PowerShell' --accept-source-agreements --accept-package-agreements
            Write-Host 'PowerShell has been updated. Please restart your shell to reflect changes' -ForegroundColor Magenta
        } else {
            Write-Host 'Your PowerShell is up to date.' -ForegroundColor Green
        }
    } catch {
        Write-Error "Failed to update PowerShell. Error: $_"
    }
}
Update-PowerShell



# my functions
function start-vm {
    param (
        [Parameter(Mandatory)]
        [string] $vm,
 
        [Parameter()]
        [switch] $Headless
    )
 
    if ($Headless.IsPresent) {
        & 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' startvm $vm --type Headless
        Start-Sleep -Seconds 10
        Write-Host 'IP: ' -NoNewline -ForegroundColor Yellow
        & 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' guestproperty get $vm /VirtualBox/GuestInfo/Net/0/V4/IP 
    } else {
        & 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' startvm $vm --type GUI
    }
}

function stop-vm {
    param (
        [Parameter(Mandatory)]
        [string] $vm,
        [Parameter()]
        [switch] $shutdown,
        [Parameter()]
        [switch] $restart
    )

    if ($shutdown.IsPresent) {
        & 'C:\Program Files\Oracle\VirtualBox\VBoxManage' controlvm $vm poweroff
    } else {
        & 'C:\Program Files\Oracle\VirtualBox\VBoxManage' controlvm $vm acpipowerbutton
    }

    if ($restart.IsPresent) {
        & 'C:\Program Files\Oracle\VirtualBox\VBoxManage' controlvm $vm reset 
    }

}

function get-vm {
    param (
        [Parameter]
        [string] $vm,
        [Parameter()]
        [switch] $Running
    )
 
    if ($Running.IsPresent) {
        & 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' list runningvms
    } else {
        & 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' list vms
    }
}

function get-vmip {
    param (
        [Parameter(Mandatory)]
        [string] $vm
    )
    Write-Host $vm -ForegroundColor Yellow
    & 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' guestproperty get $vm /VirtualBox/GuestInfo/Net/0/V4/IP
}

function update-guest {
    param (
        [Parameter()]
        [string] $vm
    )
    & vboxmanage.exe guestcontrol $vm updateguestadditions --verbose
}

function enable-pihole {
    Set-DnsClientServerAddress 'Wi-Fi' -ServerAddresses '192.168.50.2'
}

function disable-pihole {
    Set-DnsClientServerAddress 'Wi-Fi' -ResetServerAddresses
}

function reload-profile {
    & $PROFILE
}

# Make it easy to edit this profile once it's installed
function Edit-Profile {
    if ($host.Name -match 'ise') {
        $psISE.CurrentPowerShellTab.Files.Add($profile.CurrentUserAllHosts)
    } else {
        code $profile.CurrentUserAllHosts
    }
}

#
# Aliases
#
function Get-PubIP {
    (Invoke-WebRequest http://ifconfig.me/ip ).Content
}
function unzip ($file) {
    Write-Output('Extracting', $file, 'to', $pwd)
    $fullFile = Get-ChildItem -Path $pwd -Filter .\cove.zip | ForEach-Object { $_.FullName }
    Expand-Archive -Path $fullFile -DestinationPath $pwd
}


Function Get-DiskFree() {
    Get-CimInstance -ClassName Win32_LogicalDisk | Select-Object -Property DeviceID, @{'Name' = 'FreeSpace (GB)'; Expression = { [int]($_.FreeSpace / 1GB) } }
} # end Get-DiskFree

$host.PrivateData.ErrorForeGroundColor = 'Green'
$ProgressPreference = 'SilentlyContinue'
$PSDefaultParameterValues['Install-Module:Scope'] = 'CurrentUser'
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
}

