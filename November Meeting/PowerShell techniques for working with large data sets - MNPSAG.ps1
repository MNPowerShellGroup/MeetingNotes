##
##  Techniques for working with large data sets in PowerShell
##
##  Tim Curwick
##  MN PowerShell Automation Group 11/14/17
##

#region  Avoid writing excessively to console

##  Avoid Write-Progress

#  In a real life example, Write-Progress took longer than the actual code

for ( $x=0; $x -lt $Import.Count; $x++ )
    {
    Write-Progress -Activity "Creating Hashtable" -Status "$i of $Count" -PercentComplete (($i/$Count)*100)
    # code
    $i++
    }
Write-Progress -Activity "Creating Hashtable" -Completed


##  Update status sparingly

#  Slow
ForEach ( $i in 1..100000 )
    {
    # code
    $i
    }

#  Fast
ForEach ( $i in 1..100000 )
    {
    If ( $i % 10000 -eq 0 ) { $i }
    }

#endregion


#region  Don't redo work


#  Real life bad example

foreach ($license in $licenses) 
{              
    # code
    $users = Get-MsolUser -all |
        where { $_.licenses.accountskuid -contains $license.accountskuid }
    
    # more code
}


#  Real life bad example

Get-Mailbox -ResultSize Unlimited |
    Select-Object -Property DisplayName, PrimarySMTPAddress, UserPrincipalName, SAMAccountName, RecipientTypeDetails, Identity, OrganizationalUnit, DistinguishedName |
    Where {$_.OrganizationalUnit -like "ab.corp*"} |
    Export-Csv .\AB_Mbx.csv -NoTypeInformation
$NAMBX = Import-Csv .\AB_Mbx.csv

Get-Mailbox -ResultSize Unlimited |
    Select-Object -Property DisplayName, PrimarySMTPAddress, UserPrincipalName, SAMAccountName, RecipientTypeDetails, Identity, OrganizationalUnit, DistinguishedName |
    Where {$_.OrganizationalUnit -like "cd.corp*"} |
    Export-Csv .\CD_Mbx.csv -NoTypeInformation
$LAMBX = Import-Csv .\CD_Mbx.csv

Get-Mailbox -ResultSize Unlimited |
    Select-Object -Property DisplayName, PrimarySMTPAddress, UserPrincipalName, SAMAccountName, RecipientTypeDetails, Identity, OrganizationalUnit, DistinguishedName |
    Where {$_.OrganizationalUnit -like "ef.corp*"} |
    Export-Csv .\EF_Mbx.csv -NoTypeInformation
$APMBX = Import-Csv .\EF_Mbx.csv

Get-Mailbox -ResultSize Unlimited |
    Select-Object -Property DisplayName, PrimarySMTPAddress, UserPrincipalName, SAMAccountName, RecipientTypeDetails, Identity, OrganizationalUnit, DistinguishedName |
    Where {$_.OrganizationalUnit -like "gh.corp*"} |
    Export-Csv .\GH_Mbx.csv -NoTypeInformation
$EUMBX = Import-Csv .\GH_Mbx.csv

Get-Mailbox -ResultSize Unlimited |
    Select-Object -Property DisplayName, PrimarySMTPAddress, UserPrincipalName, SAMAccountName, RecipientTypeDetails, Identity, OrganizationalUnit, DistinguishedName |
    Where {$_.OrganizationalUnit -like "ij.contoso*"} |
    Export-Csv .\IJ_Mbx.csv -NoTypeInformation
$MeatMBX = Import-Csv .\IJ_Mbx.csv

Get-Mailbox -ResultSize Unlimited |
    Select-Object -Property DisplayName, PrimarySMTPAddress, UserPrincipalName, SAMAccountName, RecipientTypeDetails, Identity, OrganizationalUnit, DistinguishedName |
    Where {$_.OrganizationalUnit -like "corp.contoso*"} |
    Export-Csv .\Corp_Mbx.csv -NoTypeInformation
$CorpMbx = Import-Csv .\Corp_Mbx.csv


##  Move any code out of a loop that doesn't need to be repeated

#  Slow

ForEach ( $Dept in $Depts )
    {
    ForEach ( $User in $Users[$Dept] )
        {
        $User.NewOU = 'OU="' + $Dept.SubString + '",' + $UserOU
        # more code
        }
    }


#  Fast
#  *** In later testing, this specific example from the lecture was found
#  to be of negligible benefit, but the general concept still applies.

ForEach ( $Dept in $Depts )
    {
    $DeptOU = 'OU="' + $Dept.SubString + '",' + $UserOU

    ForEach ( $User in $Users[$Dept] )
        {
        $User.NewOU = $DeptOU
        # more code
        }
    }

#endregion


#region  Avoid pipelines

#  Slow
$Users | Where-Object Department -eq 'Finance' | ForEach-Object { <# code #> }


#  Faster
#  PowerShell 3+
$Users.Where({ $_.Department -eq 'Finance'}).ForEach({ <# code #> })

#  PowerShell 4+
$Users.Where{ $_.Department -eq 'Finance'}.ForEach{ <# code #> }


#  Fasterer 
ForEach ( $User in $Users )
    {
    If ( $User.Department -eq 'Finance' )
        {
        # code
        }
    }

#  Fastest - Use hashtables  (See below)

#endregion


#region  Loops

#  Keyword "ForEach" loops are fastest
ForEach ( $User in $Users )
    {
    #  code
    }

ForEach ( $i in 0..($Users.Count - 1) )
    {
    $Users[$i]
    }


#  Keyword "For" loops are a close second for when you need to do fancy stuff
For ( $i = 1; $i -lt $Users.Count; $i *= 10 )
    {
    $Users[$i]
    }
 
#  All other loops are slower (or much slower   
#  Cmdlet ForEach-Object loops
#  Alias ForEach (for ForEach-Object) loops
#  Method .ForEach() loops
#  Keyword While loops
#  Keyword Do/While and Do/Until loops

#endregion


#region  Avoid floating point math

#  NEVER MIND

#  *** In later testing, this was found to be of negligible benefit
#  for the types of scripts we were discussing.

#endregion


#region  Use arraylists for collection building

#  Slow
$SIDList = @()
ForEach ( $User in $Users )
    {
    # code
    $SIDList += $User.SID
    }


#  Fast
$SIDList = [System.Collections.ArrayList]@()
ForEach ( $User in $Users )
    {
    # code
    $Null = $SIDList.Add( $User.SID )
    }


# Fast (alternate syntax to dump output of Add command)
$SIDList = [System.Collection.ArrayList]@()
ForEach ( $User in $Users )
    {
    # code
    [void]$SIDList.Add( [pscustomobject]@{ Sid = $User.Sid; }  )
    }

#endregion


#region  Filter at database


# Dynamically build AD query
$ADFilter = $UserList.ForEach{ "SamAccountName -eq `"$_`"" } -join ' -or '

Get-ADUser -Filter $ADFilter

#endregion


#region  Hashtables

##  Arrays vs Hashtables

#  Arrays

$MyArray = @(
    'Value1'
    'Value2'
    'Value3' )

$MyArray[0]  # is 'Value1'
$MyArray[1]  # is 'Value2'
$MyArray[2]  # is 'Value3'

#  Very slow at large scales
$MyArray += 'Value4'


#  Hashtables

$MyHash = @{
    A   = 'Value1'
    Bee = 'Value2'
    C   = 'Value3' }

$MyHash['A']   # is 'Value1'
$MyHash['Bee'] # is 'Value2'
$MyHash['C']   # is 'Value3'


#  Slow
$MyHash += @{ D = 'Value4' }

#  Fast
$MyHash.Add( 'E', 'Value5' )



##  Convert array to hashtable for fast referencing

#  Slow

ForEach ( $User in $Users )
    {
    $Group = $Groups | Where-Object DistinguishedName -eq $User.PrimaryGroup
    }


#  Fast

$GroupHash = @{}

ForEach ( $Group in $Groups )
    {
    $GroupHash.Add( $Group.DistinguishedName, $Group )
    }

ForEach ( $User in $Users )
    {
    $GroupHash[$User.PrimaryGroup]
    }

#  Also works with arrays of keys to get arrays of values
$GroupHash[$User.MemberOf]



##  Create hashtable index for fast referencing to original array

$GIndex = @{}
ForEach ( $i in 0..($Groups.Count-1) )
    {
    $GIndex.Add( $Groups[$i].DistinguishedName, $i )
    }

$Groups[$GIndex[$User.PrimaryGroup]]


#  Also works with arrays of keys to get arrays of values
$Groups[$GIndex[$User.MemberOf]]



##  Hashtable query (single property)

#  Slow
$Users | Where-Object Department -eq 'Finance'


#  Slow
ForEach ( $Dept in $Depts )
    {
    $Users | Where-Object Department -eq $Dept
    }


#  Fast
$UserHash = $Users | Group-Object -Property Department -AsHashTable
$UserHash['Finance']


#  Fast
ForEach ( $Dept in $Depts )
    {
    $UserHash[$Dept]
    }


##  Hashtable query (multiple properties)

#  Slow
$Users | Where-Object { $_.Department -eq 'Finance' -and $_.City -eq 'Chicago' }


#  Slow
ForEach ( $Dept in $Depts )
    {
    ForEach ( $City in $Cities )
        {
        $Users | Where-Object { $_.Department -eq $Dept -and $_.City -eq $City }
        }
    }

#  Fast
$UserHash = $Users | Group-Object -Property { $_.Department + '.' + $_.City } -AsHashTable
$UserHash['Finance.Chicago']


#  Fast
ForEach ( $Dept in $Depts )
    {
    ForEach ( $City in $Cities )
        {
        $UserHash["$Dept.$City"]
        }
    }

#endregion


#region  Hashset for fast deduplication

#  List of distinguished names with duplicates
#  PS 3(4?)+
$Groups = $Users.MemberOf + $Users.PrimaryGroup

#  PS 2
$Groups = $Users | ForEach-Object { $_.MemberOf; $_.PrimaryGroup }

#  Slow
$Groups = $Groups | Select-Object -Property * -Unique
$Groups = $Groups | Sort-Object -Unique


#  Fast
$Groups = [array][System.Collections.Generic.Hashset[string]]$Groups


#  Can also be used to dedup collections on the fly
$Groups = [System.Collections.Generic.Hashset[string]]@()

ForEach ( $User in $Users )
    {
    #  Add method return $True if add successful, $False if duplicate
    $Null = $Groups.Add( $User.PrimaryGroup )

    ForEach ( $Group in $User.MemberOf )
        {
        $Null = $Groups.Add( $Group )
        }
    }

$Groups = [array]$Groups

#endregion
