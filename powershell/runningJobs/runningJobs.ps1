### process commandline arguments
[CmdletBinding()]
param (
   [Parameter(Mandatory = $True)][string]$vip, #the cluster to connect to (DNS name or IP)
   [Parameter(Mandatory = $True)][string]$username, #username (local or AD)
   [Parameter()][string]$domain = 'local' #local or AD domain
)

### source the cohesity-api helper code
. ./cohesity-api

### authenticate
apiauth -vip $vip -username $username -domain $domain

$finishedStates = @('kCanceled', 'kSuccess', 'kFailure')

### protection runs
$runs = api get protectionRuns?numRuns=999999`&excludeTasks=true | sort-object -property {$_.jobName}, {$_.backupRun.stats.startTimeUsecs} #| ?{ $_.copyRun.length -gt 1 }
$overallstatus = 'No Jobs Running'
"`nRunning Jobs:"
"=============`n"
"JobName,StartTime,TargetType,Status" | Out-File -FilePath ./runningJobs.csv
foreach ($run in $runs){
   $jobName = $run.jobName
   $runStartTime = $run.backupRun.stats.startTimeUsecs
   $startTime = usecsToDate $runStartTime
   $JID = $run.JobId
   $jRunID = $run.backupRun.jobRunId
   "$run" | Out-File -FilePath ./object.csv -Append
    foreach ($copyRun in $run.copyRun){
        if ($copyRun.status -notin $finishedStates){
            $overallstatus = $null
            $targetType = $copyRun.target.type.substring(1)
            $status = $copyRun.status.substring(1)
            "{0,-20} {1,-22} {2,-10} {3}" -f ($jobName, $startTime, $targetType, $status)
            "$jobName, $startTime, $targetType, $status" | Out-File -FilePath ./runningJobs.csv -Append
            #"$copyRun" | Out-File -FilePath ./object.csv -Append
            $cjob = @{
                "copyTaskUid" = @(
                    @{
                        "clusterId"             = $copyRun.taskUid.clusterId;
                        "clusterIncarnationId"  = $copyRun.taskUid.clusterIncarnationId;
                        "id"                    = $copyRun.taskUid.id;
                    }
                )
                "jobRunId"= $jRunID;
            }
            Write-Host "Cancelling Protection Job:" $jobName
            $cjob | Out-File -FilePath ./cjob.json -Append
            $cjob.copyTaskUid | Out-File -FilePath ./cjobtask.json -Append
            $null = api post "protectionRuns/cancel/$JID"
        }
    }
}
$overallstatus
$overallstatus | Out-File -FilePath ./runningJobs.csv -Append
"`nOutput written to runningJobs.csv`n"
