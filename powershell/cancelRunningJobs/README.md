# Cohesity Cancel Running Jobs

Warning: this code is provided on a best effort basis and is not in any way officially supported or sanctioned by Cohesity. The code is intentionally kept simple to retain value as example code. The code in this repository is provided as-is and the author accepts no liability for damages resulting from its use.

This powershell script simply cancels running jobs. For each running job, the script will report the cancelled job by:

* job name
* start time


## Download the script

Run these commands from PowerShell to download the script(s) into your current directory

```powershell
# Begin download commands
(Invoke-WebRequest -Uri https://raw.githubusercontent.com/etang-cohesity/scripts/master/powershell/cancelRunningJobs/cancelRunningJobs.ps1).content | Out-File cancelRunningJobs.ps1; (Get-Content cancelRunningJobs.ps1) | Set-Content cancelRunningJobs.ps1
(Invoke-WebRequest -Uri https://raw.githubusercontent.com/etang-cohesity/scripts/master/powershell/cancelRunningJobs/cohesity-api.ps1).content | Out-File cohesity-api.ps1; (Get-Content cohesity-api.ps1) | Set-Content cohesity-api.ps1
# End download commands
```

## Components

* cancelRunningJobs.ps1: the main powershell script
* cohesity-api.ps1: the Cohesity REST API helper module

Place both files in a folder together and run the main script like so:

```powershell
./cancelRunningJobs.ps1 -vip mycluster -username admin -domain local
```

```text
Connected!

List of jobs cancelled:
=======================

Cancelled JobName    StartTime
vm                   2019-12-20 10:43:11 AM

Output written to cancelRunningJobs.csv
```
