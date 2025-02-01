function Get-AzureUserDetails(){
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string]
        $UserName
    )
    begin {
        Connect-MgGraph -Credential 'pdadmin@millenniumhealth.com' -Scopes GroupMember.ReadWrite.All -NoWelcome
    }
    process {}
    end {
        Disconnect-MgGraph
    }
}
Get-AzureUserDetails