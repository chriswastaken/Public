#CPetty ComputerBoostrap
#8.25.2016

#Enable Hyper-V
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All

#Set Powershell Taskbar Customization
$PSonWinXPath = "HKCU:\software\microsoft\windows\currentversion\explorer\Advanced\"
$PSonWinXName = "DontUsePowershellonWinX"
if(get-itemproperty $PSonWinXPath -Name $PSonWinXName -verbose | select -Expand DontUsePowerShellOnWinX){set-itemproperty $PSonWinXPath -Name $PSonWinXName -Value 1 -verbose}

#Set ExecutionPolicy
set-executionpolicy -scope localmachine -executionpolicy remotesigned

#Download Chocolatey Installer
iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))

#List of Commonly downloaded Apps
$Apps = "googlechrome",
	    "notepadplusplus.install",
	    "flashplayerplugin",
	    "flashplayeractivex",
	    "7zip.install",
	    "vlc",
	    "keepass.install",
	    "putty.install",
	    "winscp.install",
	    "windirstat",
	    "pester",
	    "sourcetree",
	    "greenshot",
	    "linqpad5.install",
	    "steam",
	    "spotify",#should be done as regular user
	    "f.lux",
	    "everything",
	    "logparser",
	    "rsat"
	
CInst -y $Apps
