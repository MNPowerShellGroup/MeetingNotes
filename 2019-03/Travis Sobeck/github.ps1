param ([object]$WebHookData)

$Inputs = ConvertFrom-JSON $webhookdata.RequestBody
$Inputs
# If Org level webhooks send 2 posts, one is junk and can be ignored
if ($Inputs.hook.type -eq 'Organization'){exit}
($jobID = $PSPrivateMetadata.JobId.Guid)
($rbHost = $env:COMPUTERNAME)

#region Extract infro from Github commit
$authorEmail = $Inputs.head_commit.author.email
"Author: $authorEmail"
($ref = (($Inputs.ref).Split('/'))[-1])
"Ref: $ref"   
$recipient = $Inputs.head_commit.author.email
$user = $Inputs.head_commit.committer.name
$message = $Inputs.head_commit.message
$message += "`n"
$files = $Inputs.head_commit.modified
$files = $files + $Inputs.head_commit.added
$deleted = $Inputs.head_commit.removed
"Deleted Files:`n $deleted `n"
"Files changed/added:`n $files`n"
$repo = $Inputs.repository.name
"Repo: $repo"
$org = $Inputs.repository.owner.name
"Org: $org"
$server = (($Inputs.repository.url).Split('/'))[2]
"Server: $server"
#endregion