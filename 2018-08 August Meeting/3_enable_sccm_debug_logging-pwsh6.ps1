

#--------------enable debug logging in CM client-----------------

PARAM ([Parameter(Mandatory=$true, HelpMessage="Computer", ValueFromPipeline=$true)][ValidateNotNullOrEmpty()][string]$ComputerName)   

[uint32]$LogLevel = 0 # 0 for verbose;
[uint32]$LogMaxSize = (3 * 1048576) # in Bytes
[uint32]$LogMaxHistory = 5 # number of log files to keep
$DebugLogging = $true # enable debug logging

Invoke-CimMethod -ComputerName $ComputerName -Namespace root\ccm -ClassName sms_client -MethodName SetGlobalLoggingConfiguration -Arguments @{ DebugLogging = $DebugLogging ; LogLevel = $LogLevel ; LogMaxHistory = $LogMaxHistory ; LogMaxSize = $LogMaxSize}