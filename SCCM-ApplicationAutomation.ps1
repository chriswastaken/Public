$Global:SiteCode = "BCI"
$Global:SCCMServer = "CM01.bcinc.local"


function Get-CMApplicationsInFolder{
[cmdletbinding()]
 param($SiteCode,$SCCMServer,$FolderName)

 $WMIContainerSplat = @{
  Namespace = "root\sms\Site_$SiteCode"
  Query = "Select ContainerNodeID,Name,ObjectType from SMS_ObjectContainerNode"
  Computername = $SCCMServer
 }

 $ContainerNodeID = (Get-WMIObject @WMIContainerSplat | ? {($_.Name -eq $FolderName)-and($_.ObjectType -eq 6000)}).ContainerNodeID

 $WMIApplicationSplat = @{
  Namespace = "root\sms\Site_$SiteCode"
  Computername = $SCCMServer
  Query = "select InstanceKey,ContainerNodeID from SMS_ObjectContainerItem where ContainerNodeID=$ContainerNodeID "
 }
 
 Get-WmiObject @WMIApplicationSplat | %{Get-CMApplication -ModelName $_.InstanceKey}

}#End function Get-CMApplicationsInFolder

function Create-CMAutomationManufacturerFolder{
 [cmdletbinding()]
 param($ParentFolderName,$ManufacturerName)

 $Modes = "Application",
          "DeviceCollection\Applications",
          "UserCollection\Applications",
          "ConfigurationBaseline\Applications",
          "ConfigurationItem\Applications"

 foreach($Mode in $Modes){
  $Folder = Get-Item "$SiteCode`:\$Mode\$ParentFolderName\$ManufacturerName" -ErrorAction SilentlyContinue
  if(!$Folder){New-Item "$SiteCode`:\$Mode\$ParentFolderName\$ManufacturerName"}
 }

}#End function Create-CMManufacturerFolder

function Process-CMAutomationCollections{ 
 [cmdletbinding()]
 param($ApplicationName,$LimitingDeviceCollectionName,$LimitingUserCollectionName,$ParentFolderName,$SiteCode)
 
 $Application = Get-CMApplication -Name $ApplicationName
 $DesiredUserCollections = "APPInstall-$($Application.LocalizedDisplayName) $($Application.SoftwareVersion)-USER_AVAILABLE",
                           "APPInstall-$($Application.LocalizedDisplayName) $($Application.SoftwareVersion)-USER_AVAILABLE_NoAdmin"
 $DesiredDeviceCollections = "APPInstall-$($Application.LocalizedDisplayName) $($Application.SoftwareVersion)-DEVICE_AVAILABLE",
                             "APPInstall-$($Application.LocalizedDisplayName) $($Application.SoftwareVersion)-DEVICE_REQUIRED",
                             "APPInstall-$($Application.LocalizedDisplayName) $($Application.SoftwareVersion)-DEVICE_REQUIRED_NoMaintenance"
 
 foreach($DesiredUserCollection in $DesiredUserCollections){
  $UserCollection = Get-CMCollection -Name $DesiredUserCollection
  if(!$UserCollection){$UserCollection = New-CMCollection -CollectionType User -Name $DesiredUserCollection -LimitingCollectionName $LimitingUserCollectionName}
  Move-CMObject -FolderPath "$SiteCode`:\UserCollection\Applications\$ParentFolderName\$($Application.Manufacturer)" -InputObject $UserCollection

 }
 foreach($DesiredDeviceCollection in $DesiredDeviceCollections){
  $DeviceCollection = Get-CMCollection -Name $DesiredDeviceCollection
  if(!$DeviceCollection){$DeviceCollection = New-CMCollection -CollectionType Device -Name $DesiredDeviceCollection -LimitingCollectionName $LimitingDeviceCollectionName}
  Move-CMObject -FolderPath "$SiteCode`:\DeviceCollection\Applications\$ParentFolderName\$($Application.Manufacturer)" -InputObject $DeviceCollection
 }



}#End function Process-CMAutomationCollections

function Process-CMAutomationDeployments{
 [cmdletbinding()]
 param($ApplicationName)
 $Application = Get-CMApplication -Name $ApplicationName

 $UserAvailableSplat = @{
  AppRequiresApproval = $True
  CollectionName = "APPInstall-$($Application.LocalizedDisplayName) $($Application.SoftwareVersion)-USER_AVAILABLE"
  DeployAction = Install
  DeployPurpose = Available
  InputObject = $Application
  UserNotification = DisplayAll
 }
 Start-CMApplicationDeployment @UserAvailableSplat
 $UserAvailableNoAdminSplat = @{
  AppRequiresApproval = $False
  CollectionName = "APPInstall-$($Application.LocalizedDisplayName) $($Application.SoftwareVersion)-USER_AVAILABLE_NoAdmin"
  DeployAction = Install
  DeployPurpose = Available
  InputObject = $Application
  UserNotification = DisplayAll
 }
 Start-CMApplicationDeployment @UserAvailableNoAdminSplat
 $DeviceAvailableSplat = @{
  CollectionName = "APPInstall-$($Application.LocalizedDisplayName) $($Application.SoftwareVersion)-DEVICE_AVAILABLE"
  DeployAction = Install
  DeployPurpose = Available
  InputObject = $Application
  UserNotification = DisplayAll
 }
 Start-CMApplicationDeployment @DeviceAvailableSplat
 $DeviceRequiredSplat = @{
  CollectionName = "APPInstall-$($Application.LocalizedDisplayName) $($Application.SoftwareVersion)-DEVICE_REQUIRED"
  DeployAction = Install
  DeployPurpose = Required
  InputObject = $Application
  UserNotification = DisplaySoftwareCenterOnly
 }
 Start-CMApplicationDeployment @DeviceRequiredSplat
 $DeviceRequiredNoMaintSplat = @{
  CollectionName = "APPInstall-$($Application.LocalizedDisplayName) $($Application.SoftwareVersion)-DEVICE_REQUIRED_NoMaintenance"
  DeployAction = Install
  DeployPurpose = Required
  InputObject = $Application
  UserNotification = DisplaySoftwareCenterOnly
  OverrideServiceWindow = $True
  RebootOutsideServiceWindow = $True
 }
 Start-CMApplicationDeployment @DeviceRequiredNoMaintSplat
}#End function Process-CMAutomationDeployments


$CMApplicationsInFolderSplat = @{
 SiteCode = $Global:SiteCode
 SCCMServer = $Global:SCCMServer
 FolderName = ".Test Processing"
 OutVariable = TestApplications
}
Get-CMApplicationsInFolder @CMApplicationsInFolderSplat

Create-CMAutomationManufacturerFolder -ParentFolderName "2_Testing" -ManufacturerName $($TestApplications.Manufacturer)

$CMAutomationCollectionsSplat = @{
 SiteCode = $Global:SiteCode
 ApplicationName = $($TestApplications.LocalizedDisplayName)
 LimitingDeviceCollectionName = "BETA Devices"
 LimitingUserCollectionName = "BETA Users"
 ParentFolderName = "2_Testing"
}
Process-CMAutomationCollections @CMAutomationCollectionsSplat

Process-CMAutomationDeployments $($TestApplications.LocalizedDisplayName)

