### process commandline arguments
[CmdletBinding()]
param (
   [Parameter(Mandatory = $True)][string]$vip, #the cluster to connect to (DNS name or IP)
   [Parameter(Mandatory = $True)][string]$username, #username (local or AD)
   [Parameter()][string]$domain = 'local' #local or AD domain
)

### source the cohesity-api helper code
. $(Join-Path -Path $PSScriptRoot -ChildPath cohesity-api.ps1)

### start output file
$outfile = $(Join-Path -Path $PSScriptRoot -ChildPath cancelRunningJobs.csv)

### authenticate
apiauth -vip $vip -username $username -domain $domain

$finishedStates = @('kCanceled', 'kSuccess', 'kFailure')

### get protection runs
$runs = api get protectionRuns?numRuns=999999`&excludeTasks=true 
"`nList of jobs cancelled:"
"=======================`n"
"{0,-20} {1}" -f ("Cancelled JobName", "StartTime")
"JobName,StartTime" | Out-File -FilePath $outfile
foreach ($run in $runs){
   if ($run.backupRun.status -notin $finishedStates) {
      $jobName = $run.jobName
      $jobID = $run.JobId
      $jobRunID = $run.backupRun.jobRunId
      $runStartTime = $run.backupRun.stats.startTimeUsecs
      $startTime = usecsToDate $runStartTime
      "{0,-20} {1}" -f ($jobName, $startTime)
      "$jobName, $startTime" | Out-File -FilePath $outfile -Append
      $cjob = @{
        "jobRunId"= $jobRunID;
      }
    $null = api post "protectionRuns/cancel/$jobID" $cjob
   }
}
Write-Host "`nCompleted"
