Function New-Something {
<#
.SYNOPSIS
    This is a basic overview of what the script is used for..
 
 
.NOTES
    Name: 
    Author: 
    Version: 
    DateCreated: 
 
 
.EXAMPLE
    Get-Something -UserPrincipalName "username@thesysadminchannel.com"
 
 
.LINK
    https://thesysadminchannel.com/powershell-template -
#>
 
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0
            )]
        [string[]]  $UserPrincipalName
    )
 
    BEGIN {}
 
    PROCESS {}
 
    END {}
}