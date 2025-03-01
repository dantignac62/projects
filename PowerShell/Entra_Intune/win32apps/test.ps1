# Define Log location
$LogPath = ".\" #"$env:ProgramData\Microsoft\IntuneManagementExtension\Logs"
$log = -join $(([System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)), '.log' )
$logFile = Join-Path -Path $LogPath -ChildPath $log

# Ensure Log Directory Exists
if (!(Test-Path $LogPath)) {
    New-Item -Path $LogPath -ItemType Directory -Force
}
function Write-log {

    [CmdletBinding()]
    Param(
        [parameter(Mandatory = $false)]
        [String]$Path = $logFile,

        [parameter(Mandatory = $true)]
        [String]$Message,

        [parameter(Mandatory = $false)]
        [String]$Component = $MyInvocation.MyCommand.Name,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Warning", "Error")]
        [String]$Type = 'INFO'
    )

    switch ($Type) {
        "Info" { [int]$Type = 1 }
        "Warning" { [int]$Type = 2 }
        "Error" { [int]$Type = 3 }
    }

    # Create a log entry
    $Content = "<![LOG[$Message]LOG]!>" + `
        "<time=`"$(Get-Date -Format "HH:mm:ss.ffffff")`" " + `
        "date=`"$(Get-Date -Format "M-d-yyyy")`" " + `
        "component=`"$Component`" " + `
        "context=`"$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " + `
        "type=`"$Type`" " + `
        "thread=`"$([Threading.Thread]::CurrentThread.ManagedThreadId)`" " + `
        "file=`"`">"

    # Write the line to the log file
    Add-Content -Path $logFile -Value $Content
}
Start-Transcript -Path $logFile -Append
Write-log -Message 'Start Application install' 
function test-function {
    Write-log -Message 'Informational message from function'
}




Stop-Transcript 