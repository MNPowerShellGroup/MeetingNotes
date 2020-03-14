param ([object]$WebHookData)
try{
    $ErrorActionPreference = 'Stop'
    #region Init
        $Inputs = ConvertFrom-JSON $webhookdata.RequestBody
        $Inputs # I like to dump it to output so you know what you got before touching the data
        ($jobID = $PSPrivateMetadata.JobId.Guid) # This references the specific job being run for logging, debugging, etc
        ($rbHost = $env:COMPUTERNAME) # this is more usefull if you are using hybrid runbook workers
        Add-Member -InputObject $Inputs -Name "jobID" -Value $jobID -MemberType NoteProperty # this is a special case because $Inputs is a PSCustomObj
        ## This is a good time to log the start of the job without your own processes :)
    #endregion
    
    ######
    # One of the most useful things you can do for yourself is stash the information that comes before doing anything with it.  There are many options, you could 
    # write to files, logging systems, etc.  I find writing to a database a good option, mondern dbs are good at understanding JSON.  Below is an example of using a MSSQL DB.
    # What you use is less important than implementing something.
    ######
    #region Replay JobID or Stash Job data in DB
        #region Replay JobID, this is used to re-run a job or as the response to FLOW
            if ($Inputs.replayJobID) # I use 'replayJobID' as my key, be feel free to use whatever you want
            {
                ($msg = "Pull Job details from SQL DB for $($Inputs.replayJobID)")
                #Import-Module SqlServer
                $db = Get-AutomationVariable -Name 'db'
                $sqlServer = Get-AutomationVariable -Name 'dbServer'
                #$sqlInstance = Get-SqlInstance -ServerInstance $sqlServer #-Credential $sqlCred #haven't vigured creds out, crappy module
                $table = 'runbookJobs'
                #($jobs = (Invoke-Sqlcmd -Query "SELECT jobs from $table Where JSON_VALUE(jobs,'$.jobID') = '$($Inputs.replayJobID)'" -Database $db -ServerInstance $sqlInstance).jobs | ConvertFrom-Json)
                #validate
                if ($jobs -eq $null)
                {
                    ($msg = "Found no records for $($Inputs.replayJobID)")
                    Throw $msg
                }
                $jobs.jobID = $jobID
                # Need to catpure and maintain approval information if available
                # The following are relavent if this job is called after an approval from FLOW
                if ($Inputs.'Approver ID'){$approverID = $Inputs.'Approver ID'}
                if ($Inputs.approved){$approved = $Inputs.approved}
                $Inputs = $jobs
                Add-Member -InputObject $Inputs -MemberType NoteProperty -Name 'replay' -Value $true
                Add-Member -InputObject $Inputs -MemberType NoteProperty -Name 'approverID' -Value $approverID
                Add-Member -InputObject $Inputs -MemberType NoteProperty -Name 'approved' -Value $approved
            }
        #endregion

        #region Stash input into DB, New incoming job.
            else
            {
                try
                {
                    ## again, substitue in your own approach, this is just an example of using MSSQL
                    "Sending Job to SQL DB"
                    #Import-Module SqlServer
                    $db = Get-AutomationVariable -Name 'db'
                    $sqlServer = Get-AutomationVariable -Name 'dbServer'
                    #$sqlInstance = Get-SqlInstance -ServerInstance $sqlServer #-Credential $sqlCred #haven't vigured creds out, crappy module
                    $table = 'runbookJobs'
                    $json = $Inputs | ConvertTo-Json
                    $sqlCommand = "declare @json nvarchar(max) = '$json';"
                    $sqlCommand += "INSERT INTO $table Values(@json)"      
                    #Invoke-Sqlcmd -Query $sqlCommand -Verbose -Database $db -ServerInstance $sqlInstance
                }
                catch
                {
                    ## Fill in your own process for handling failures
                }
            }
        #endregion

    #endregion

    ## Do some stufff!

    ## Go get approval
    $flowURI = Get-AutomationVariable -Name 'flowURI'
    $body = @{
        authorizersEmails = Get-AutomationVariable -Name 'authEmails'
        requester = $Inputs.requester
        requesterEmail = $Inputs.email
        replayJobID = $jobID
        requesterMessage = "Your request is being worked on!"
        approvalMessage = "$($Inputs.requester) wants $($Inputs.'Pick one') and $($Inputs.'Pick many') and $($Inputs.'Pick from dropdown')"
        rbURI = Get-AutomationVariable -Name 'rbURI'
    } | ConvertTo-Json
    Invoke-WebRequest -Uri $flowURI -Body $body -Method Post -UseBasicParsing -ContentType 'application/json'


}
catch{}