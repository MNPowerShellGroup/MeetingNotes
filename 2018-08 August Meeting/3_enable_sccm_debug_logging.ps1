

#--------------enable debug logging in CM client-----------------

PARAM ([Parameter(Mandatory=$true, HelpMessage="Computer", ValueFromPipeline=$true)][ValidateNotNullOrEmpty()][string]$ComputerName)   

$LogLevel = 0 # 0 for verbose;
$LogMaxSize = (3 * 1048576) # in Bytes
$LogMaxHistory = 5 # number of log files to keep
$DebugLogging = $true # enable debug logging

Invoke-WmiMethod -ComputerName $ComputerName -Namespace root\ccm -Class sms_client -Name SetGlobalLoggingConfiguration -ArgumentList @($DebugLogging,$LogLevel,$LogMaxHistory,$LogMaxSize)