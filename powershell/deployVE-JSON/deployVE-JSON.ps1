
### process commandline arguments
[CmdletBinding()]
param (
    [Parameter(Mandatory = $True)][string]$inputJSON # name of JSON file
)

. .\cohesity-api.ps1
$REPORTAPIERRORS = $false

#load VE JSON file
$jsonFile = loadJson $inputJSON

### assign variables
$ip = $jsonFile.ip # ip address of the node
$netmask = $jsonFile.netmask # subnet mask
$gateway = $jsonFile.gateway # default gateway
$vmNetwork = $jsonFile.vmNetwork # VM port group name
$vmName = $jsonFile.vmName # VM name
$metadataSize = $jsonFile.metadataSize # size of metadata disk
$dataSize = $jsonFile.dataSize # size of data disk
$dnsServers = $jsonFile.dnsServers # dns servers
$ntpServers = $jsonFile.ntpServers # ntp servers
$clusterName = $jsonFile.clusterName # Cohesity cluster name
$clusterDomain = $jsonFile.clusterDomain # DNS domain of Cohesity cluster
$viServer = $jsonFile.viServer # vCenter to connect to
$viHost = $jsonFile.viHost # vSphere host to deploy OVA to
$viDataStore = $jsonFile.viDataStore # vSphere datastore to deploy OVA to
$ovfPath = $jsonFile.ovfPath # path to ova file
$licenseKey = $jsonFile.licensekey # Cohesity license key
$dataDataStore  = $jsonFile.dataDataStore # vSphere datastore to deploy Cohesity data disk


# connect to vCenter
write-host "Connecting to vCenter..."

$null = Connect-VIServer -Server $viServer -Force -WarningAction SilentlyContinue

# set OVA configuration
write-host "Setting OVA configuration..."

$ovfConfig = Get-OvfConfiguration -Ovf $ovfPath
$ovfConfig.Common.dataIp.Value = $ip
$ovfConfig.Common.dataNetmask.Value = $netmask
$ovfConfig.Common.dataGateway.Value = $gateway
$ovfConfig.DeploymentOption.Value = 'small'
$ovfConfig.IpAssignment.IpProtocol.Value = 'IPv4'
$ovfConfig.NetworkMapping.DataNetwork.Value = $vmNetwork
$ovfConfig.NetworkMapping.SecondaryNetwork.Value = $vmNetwork

# deploy OVA
write-host "Deploying OVA..."

$VMHost = Get-VMHost -Name $viHost
$datastore = Get-Datastore -Name $viDataStore
$diskformat = 'Thin'
$metadataSCSI = 'SCSI Controller 1'
$dataSCSI = 'SCSI Controller 2'
# (Optional) $cpuReservation = '2000'
# (Optional) $memoryLimit = '16'
$null = Import-VApp -Source $ovfPath -OvfConfiguration $ovfConfig -Name $vmName -VMHost $VMHost -Datastore $datastore -DiskStorageFormat $diskformat -Confirm:$false -Force

# add data and metadata disks
write-host "Adding data disks to VM..."

$VM = get-vm -Name $vmName
$null = New-HardDisk -CapacityGB $metadataSize -Confirm:$false -StorageFormat $diskformat -VM $VM -controller $metadataSCSI -WarningAction SilentlyContinue
$null = New-HardDisk -CapacityGB $dataSize -Confirm:$false -StorageFormat $diskformat -Datastore $dataDataStore -controller $dataSCSI -VM $VM -WarningAction SilentlyContinue

# (Optional) change the VM CPU reservation to 2000MHz for Intel NUC and memory to 16GB
# write-host "Changing VM CPU reservation to 2000 & memory to 16GB for Intel NUC..."
# $null = Set-VM -VM $vmName -MemoryGB $memoryLimit -Confirm:$false
# $null = Get-VMResourceConfiguration -VM $vmName | Set-VMResourceConfiguration -CpuReservationMhz $cpuReservation -MemReservationGB $memoryLimit

# power on VM
write-host "Powering on VM..."

$null = Start-VM $VM

# wait for startup
Write-Host "Waiting for VM to boot..."

apidrop -quiet
while($AUTHORIZED -eq $false){
    apiauth $ip admin -quiet
    if($AUTHORIZED -eq $false){
        Start-Sleep -Seconds 10
    }
}
apidrop -quiet

# perform cluster setup
write-host "Performing cluster setup..."

$cluster = $null
$clusterId = $null
while($cluster.length -eq 0){
    apiauth $ip admin -quiet
    if($AUTHORIZED -eq $true){
        $myObject = @{
            "clusterName" = $clusterName;
            "ntpServers" = $ntpServers;
            "dnsServers" = $dnsServers;
            "domainNames" = @(
                $clusterDomain
            );
            "clusterGateway" = $gateway;
            "clusterSubnetCidrLen" = $netmask;
            "ipmiGateway" = $null;
            "ipmiSubnetCidrLen" = $null;
            "ipmiUsername" = $null;
            "ipmiPassword" = $null;
            "enableEncryption" = $false;
            "rotationalPolicy" = 90;
            "enableFipsMode" = $false;
            "nodes" = @(
                @{
                    "id" = (api get /nexus/node/info).nodeId;
                    "ip" = "$ip";
                    "ipmiIp" = ""
                }
            );
            "clusterDomain" = $clusterDomain;
            "nodeIp" = "$ip";
            "hostname" = $clusterName
        }
        $cluster = api post /nexus/cluster/virtual_robo_create $myObject
        $clusterId = $cluster.clusterId
    }else{
        Start-Sleep -Seconds 10
    }
}
write-host "New clusterId is $clusterId"
apidrop -quiet

# wait for startup
write-host "Waiting for cluster setup to complete..."

$clusterId = $null
while($null -eq $clusterId){
    Start-Sleep -Seconds 10
    apiauth $ip admin -quiet
    $clusterId = (api get cluster).id
}
apidrop -quiet

# accept eula and enter license key
write-host "Accepting eula and applying license key..."

$signTime = (dateToUsecs (get-date))/1000000

$myObject = @{
    "signedVersion" = 1;
    "signedByUser" = "admin";
    "signedTime" = [Int64]$signTime;
    "licenseKey" = "$licenseKey"
}

while($AUTHORIZED -eq $false){
    apiauth $ip admin -quiet
    $null = api post /licenseAgreement $myObject
    if($AUTHORIZED -eq $false){
        Start-Sleep -Seconds 10
    }
}

write-host "VE Deployment Complete"
