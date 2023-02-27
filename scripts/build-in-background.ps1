$host.UI.RawUI.ForegroundColor = "White"
$host.UI.RawUI.BackgroundColor = "Black"
if (!$PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }
# store file path in $pwd_path and ensure PSScriptRoot worsk the same in both powershell 2 and 3
$pwd_path = $PSScriptRoot
Push-Location $pwd_path
$cmd_args = "$pwd_path/images-build.bat" 
&$cmd_args = Invoke-WmiMethod -Class Win32_Process -Name Create -ArgumentList cmd "$pwd_path/images-build.bat" -WindowStyle "Maximized"
Pop-Location