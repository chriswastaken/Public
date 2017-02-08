$Server="192.168.1.50"

connect-viserver $Server
#GrafanaStat collection
function Write-InfluxData{
 param(
  $Measurements,
  $InfluxDB="TestDB2",
  $InfluxServer="10.1.1.100",
  $InfluxServerPort="8086"

 )

 function get-epocdate{
 param($DateTime)
 
               #$UnixTime= [math]::Round((New-TimeSpan -Start (Get-Date -Date "01/01/1970") -End (Get-Date $DateTime)).TotalSeconds)
               #$UnixTime.ToSTring() + "000000000"
               ([int][double]::Parse((Get-Date (get-date $DateTime).ToUniversalTime() -UFormat %s))).ToString() + "000000000"
 }

$Body = $Measurements | %{
        "$($_.Name),host=$($_.SourceHost)$(if($_.DataTags){$_.DataTags|%{",$($_)"}}) value=$($_.Value)$(if($_.TimeStamp){" $(get-epocdate $_.TimeStamp)"})"
        }
$Body = $($Body|%{$_ + "`n" -replace "`r","`n"})
#if($TimeStamp){
#               $UnixTime= [math]::Round((New-TimeSpan -Start (Get-Date -Date "01/01/1970") -End (Get-Date $TimeStamp)).TotalSeconds)
#               $UnixTime = ($UnixTime.ToSTring()+ "000000000") 
#              }
$uri = "http://$($InfluxServer):$($InfluxServerPort)/write?db=$($InfluxDB)"
Invoke-RestMethod -Uri $uri -Method POST -Body $Body -Verbose -UseBasicParsing


}#End function Write-InfluxData

function Get-esxiStats{
 param($Server)

get-stat -disk -Network -Common -Memory -Cpu -MaxSamples 50 |%{
            [PSCustomObject]@{
                        Name=$_.MetricID
                        Value=$_.Value
                        SourceHost=$_.Entity
                        DataTags="$(if($_.Unit){"Unit=$($_.Unit)"})$(if($_.Instance){",Instance=$($_.Instance)"})"
                        Timestamp="$(if($_.Timestamp){$_.Timestamp})"
            }#End PSCustomObject
}#End Foreach get-stat

get-datastore -Server $Server | %{
            [PSCustomObject]@{
                        Name="DataStore-FreeSpaceGB"
                        Value=$($_.FreeSpaceGB)
                        SourceHost=$Server
                        DataTags="$(if($_.Type){"Type=$($_.Type)"})$(if($_.Name){",Instance=$($_.Name)"})"

            }
            [PSCustomObject]@{
                        Name="DataStore-CapacityGB"
                        Value=$($_.CapacityGB)
                        SourceHost=$Server
                        DataTags="$(if($_.Type){"Type=$($_.Type)"})$(if($_.Name){",Instance=$($_.Name)"})"

            }

}#end Foreach get-datastore

}#end Function get-esxistats

while($true){Write-InfluxData -Measurements $(Get-esxiStats -Server 192.168.1.50) -InfluxDB TestingDB;sleep 30}

function Test-InternetConnectionStats {
 param()
 $wc = New-Object net.webclient
 $Speed = "{0:N2} Mbit/sec"  -f ((100/(Measure-Command {$wc.Downloadfile('http://lax.testmy.net/dl-100MB',"$ENV:TEMP\speedtest.test")}).TotalSeconds)*8); del "$ENV:TEMP\speedtest.test"
 [PSCustomObject]@{
    Name="TestMy.Net_100MB_InternetTest"
    Value=$($Speed.Split(" "))[0]
    SourceHost="TestMy.Net"
 }

}#End function Test-InternetConnection