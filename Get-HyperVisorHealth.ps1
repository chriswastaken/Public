#HyperVisor health

$Servers = "HV01","HV02"

function get-HyperVisorHealth{
param($ServerName)
 if(test-connection $ServerName -count 1 -ea SilentlyContinue){
 $Temperature = (((gwmi -ComputerName $ServerName -Namespace root/cimV2/dell -Class CIM_TemperatureSensor).CurrentReading / 10) * 1.8) + 32
 $CPULoad = (gwmi -ComputerName $ServerName win32_processor).loadpercentage
 $OS = (gwmi -ComputerName $ServerName win32_OperatingSystem)
 $FreeMem = $OS.FreePhysicalMemory / 1MB
 $TotalMem = $OS.TotalVisibleMemorySize / 1MB
 $LogicalDisk = (gwmi -ComputerName $ServerName win32_logicaldisk | ? DeviceID -eq "C:")
 $FreeSpace =$LogicalDisk.FreeSpace / 1GB
 $Size =$LogicalDisk.Size / 1GB
 $Memory

 [PSCustomObject]@{ServerName=$ServerName;CPULoad=$CPULoad;FreeMemory="{0:N2}" -f $FreeMem;TotalMemory="{0:N2}" -f $TotalMem;Temperature=$Temperature;C_Freespace="{0:N2}" -f $FreeSpace;C_Size="{0:N2}" -f $Size}
 }
}