# Deploy Cohesity Virtual Edition Using PowerShell

Warning: this code is provided on a best effort basis and is not in any way officially supported or sanctioned by Cohesity. The code is intentionally kept simple to retain value as example code. The code in this repository is provided as-is and the author accepts no liability for damages resulting from its use.

This is a fork of the existing deployVE.ps1 script by Eddie Tang to incorporate JSON input file and adding additional parameter for Cohesity VE data drive on specific VI DataStore

## Note: Please use the download commands below to download the script

This PowerShell script deploys a single-node Cohesity Virtual Edition (VE) appliance on VMware vSphere. After deploying the OVA, the script performs the cluster setup, applies a license key and accepts the end-user license agreement, leaving the new cluster fully built and ready for login.

## Components

* deployVE-JSON.ps1: the main PowerShell script
* cohesity-api.ps1: the Cohesity REST API helper module

Place all files in a folder together. then, run the main script like so:

```powershell
.\deployVE-JSON.ps1 -inputJSON 'JSONfile'
```

```JSON File format
{
    "ip": "x.x.x.x",
    "netmask": "x.x.x.x",
    "gateway": "x.x.x.x",
    "vmNetwork": "VM Network",
    "vmName": "VE1",
    "metadataSize": 51,
    "dataSize": 201,
    "dnsServers": ["x.x.x.x","x.x.x.x"],
    "ntpServers": ["time.google.com"],
    "clusterName": "CohesityVE1",
    "clusterDomain": "domain.local",
    "viServer": "vcenter.domain.local",
    "viHost": "esxhost01.domain.local",
    "viDataStore": "SSD01",
    "ovfPath": "c:\\path to ova\\.ova",
    "licenseKey": "XXXX-XXXX-XXXX-XXXX",
    "dataDataStore": "HDD01"
}

```

```text
Connecting to vCenter...
Setting OVA configuration...
Deploying OVA...
Adding data disks to VM...
Powering on VM...
Waiting for VM to boot...
Performing cluster setup...
Waiting for cluster setup to complete...
Accepting eula and applying license key...
VE Deployment Complete
```

## Download the script

Run these commands from PowerShell to download the script(s) into your current directory

```powershell
# Begin download commands
(Invoke-WebRequest -Uri https://raw.githubusercontent.com/etang-cohesity/scripts/master/powershell/deployVE-JSON/deployVE-JSON.ps1).content | Out-File deployVE-JSON.ps1; (Get-Content deployVE-JSON.ps1) | Set-Content deployVE-JSON.ps1
(Invoke-WebRequest -Uri https://raw.githubusercontent.com/etang-cohesity/scripts/master/powershell/deployVE-JSON/cohesity-api.ps1).content | Out-File cohesity-api.ps1; (Get-Content cohesity-api.ps1) | Set-Content cohesity-api.ps1
(Invoke-WebRequest -Uri https://raw.githubusercontent.com/etang-cohesity/scripts/master/powershell/deployVE-JSON/VEexample.JSON).content | Out-File VEexample.JSON; (Get-Content VEexample.JSON) | Set-Content VEexample.JSON
# End download commands
```

