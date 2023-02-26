$host.UI.RawUI.ForegroundColor = "White"
$host.UI.RawUI.BackgroundColor = "Black"
if (!$PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }
# store file path in $pwd_path and ensure PSScriptRoot worsk the same in both powershell 2 and 3
$pwd_path = $PSScriptRoot
# jump to first line without clearing scrollback
Write-Output "$([char]27)[2J"
function install_software {
    # function built using https://keestalkstech.com/2017/10/powershell-snippet-check-if-software-is-installed/ as aguide
    param (
        $software_id,
        $software_name,
        $install_command,
        $verify_installed,
        $force_install
    )

    if ($verify_installed -eq $true) {
        $installed = $null -ne (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -eq $software_id })
        if ($installed -eq $false) {
            if ($force_install -eq $false) {
                # give user the option to install
                $install = Read-Host "`r`n$software_name recommended but not found. Install now? (y/[n])"
                if ($install -ieq 'y' -Or $install -ieq 'yes') { 
                    Write-Host "`r`n"
                    Write-Host "Installing $software_name..."
                    &$install_command
                    $host.UI.RawUI.BackgroundColor = "Black"
                }
                else {
                    Write-Host "skipping $software_name install"
                }
            }
            else {
                $install = Read-Host "`r`n$software_name required. Install now or quit? (y/[q])"
                # @TODO: investigate code refactoring for duplicate code
                if ($install -ieq 'y' -Or $install -ieq 'yes') { 
                    Write-Host "Installing $software_name..."
                    Invoke-Expression $install_command
                    $host.UI.RawUI.BackgroundColor = "Black"
                }
                else {
                    Write-Host "skipping $software_name install and exiting..."
                    exit
                }
            }
        }
        else {
            Write-Host "`r`n$software_name already installed." -ForegroundColor Yellow
        }
    }
    elseif ($force_install -eq $false) { 
        $install = Read-Host "`r`n$software_name recommended. Install now? (y/[n])"
        # @TODO: investigate code refactoring for duplicate code
        if ($install -ieq 'y' -Or $install -ieq 'yes') { 
            Write-Host "Installing $software_name..."
            Invoke-Expression $install_command
            $host.UI.RawUI.BackgroundColor = "Black"
        }
        else {
            Write-Host "skipping $software_name install"
        }
    }
    else {
        # force_install: true, verify_install: false
        $install = Read-Host "`r`n$software_name required. Install now or quit? (y/[q])"
        if ($install -ieq 'y' -Or $install -ieq 'yes') { 
            Write-Host "Installing $software_name..."
            Invoke-Expression $install_command
            $host.UI.RawUI.BackgroundColor = "Black"
        }
        else {
            Write-Host "skipping $software_name install and exiting..."
            exit
        }
    }
}

function restart_prompt {
    Write-Host "`r`nA restart is required for the changes to take effect. " -ForegroundColor Magenta
    $confirmation = Read-Host "`r`nRestart now (y/[n])?" 
    if ($confirmation -ieq 'y') {
        Restart-Computer -Force
    }
}

# source of the below self-elevating script: https://blog.expta.com/2017/03/how-to-self-elevate-powershell-script.html#:~:text=If%20User%20Account%20Control%20(UAC,select%20%22Run%20with%20PowerShell%22.
# Self-elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
        $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
        Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
        Exit
    }
}
# source of the above self-elevating script: https://blog.expta.com/2017/03/how-to-self-elevate-powershell-script.html#:~:text=If%20User%20Account%20Control%20(UAC,select%20%22Run%20with%20PowerShell%22.

$repo_src_owner = 'kindtek'
$repo_src_name = 'docker-to-wsl'
$repo_src_branch = 'dev'
$dir_local = "$repo_src_name/scripts"

# use windows-features-wsl-add to handle windows features install 
$winconfig = "$pwd_path/$dir_local/windows-features-wsl-add/configure-windows-features.ps1"
&$winconfig = Invoke-Expression -command "$pwd_path/windows-features-wsl-add/configure-windows-features.ps1"

# install winget and use winget to install everything else
$winget = "$pwd_path/get-latest-winget.ps1"
Write-Host "`n`r`n`rInstalling WinGet ..."
&$winget = Invoke-Expression -command "$pwd_path/windows-features-wsl-add/configure-windows-features.ps1"
        
# @TODO: find a way to check if windows terminal is installed
$software_id = $software_name = "Windows Terminal"
$install_command = "winget install Microsoft.WindowsTerminal"
$verify_installed = $false
$force_install = $false
install_software $software_id $software_name $install_command $verify_installed $force_install

$software_name = "Github CLI"
$software_id = "Git_is1"
$install_command = "winget install -e --id GitHub.cli"
$verify_installed = $true
$force_install = $true
install_software $software_id $software_name $install_command $verify_installed $force_install

$this_dir = Get-Location
Push-Location ..
Remove-Item $this_dir -Recurse -WhatIf -Confirm
git clone "https://github.com/$repo_src_owner/$repo_src_name.git" --branch $repo_src_branch
git submodule update --force --recursive --init --remote
Pop-Location

# @TODO: find a way to check if VSCode is installed
$software_id = $software_name = "Visual Studio Code (VSCode)"
$install_command = "winget install Microsoft.VisualStudioCode --override '/SILENT /mergetasks=`"!runcode,addcontextmenufiles,addcontextmenufolders`"'"
$verify_installed = $false
$force_install = $true
install_software $software_id $software_name $install_command $verify_installed $force_install

# Docker Desktop happens to work for both id and name
$software_id = $software_name = "Docker Desktop"
$install_command = "winget install --id=Docker.DockerDesktop -e"
$verify_installed = $true
$force_install = $true
install_software $software_id $software_name $install_command $verify_installed $force_install

# launch docker desktop
$docker = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
&$docker = "C:\Program Files\Docker\Docker\Docker Desktop.exe"

Write-Host "`r`nA restart may be required for the changes to take effect. " -ForegroundColor Magenta
$confirmation = Read-Host "`r`nRestart now (y/[n])?" 
if ($confirmation -ieq 'y') {
    Restart-Computer -Force
}
else {

    if ((Read-Host "`r`nopen Docker Dev environment? [y]/n") -ine 'n'  ) {
        Start-Process "https://open.docker.com/dashboard/dev-envs?url=https://github.com/kindtek/docker-to-wsl@dev"
    } 

    # start WSL docker import tool
    $file = "wsl-import.ps1"
    &$file = Start-Process powershell "wsl-import.ps1" -WindowStyle "Maximized"

    $winconfig = "$pwd_path/wsl-import.ps1"
    &$winconfig = Invoke-Expression -command "$pwd_path/wsl-import.ps1"

    $user_input = (Read-Host "`r`nopen Docker Dev environment? [y]/n")
    if ( $user_input -ine "n" ) {
        Start-Process "https://open.docker.com/dashboard/dev-envs?url=https://github.com/kindtek/docker-to-wsl@dev" -WindowStyle "Hidden"
    }  

    Write-Output "DONE! You can close this window"
}

# could be useful for later
# $cmd_args = "$pwd_path/docker-to-wsl/scripts/images-build.bat" 
# &$cmd_args = Invoke-WmiMethod -Class Win32_Process -Name Create -ArgumentList cmd "$pwd_path/docker-to-wsl/scripts/images-build.bat"
