# Define the log directory path
$logDir = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs"
# Check if the directory exists
if (-Not (Test-Path -Path $logDir)) {
    try {
        # Try to create the directory; suppress output with Out-Null
        New-Item -Path $logDir -ItemType Directory -ErrorAction Stop | Out-Null
    } catch {
        # If creation fails, write a message and exit the script
        Write-Error "The directory '$logDir' could not be created: $_"
        exit
    }
}

# Set the log file variable to the directory path
$logFile = ([System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)) + ".log"
$logFile = Join-Path -Path $logDir -ChildPath $logFile
$logFile

# Define CMTrace style logging function
function Write-Log {
    param (
        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$Component = $MyInvocation.MyCommand.Name,

        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "VERBOSE")]
        [string]$LogLevel = "INFO",

        [Parameter(Mandatory = $false)]
        [string]$LogFile = $logFile  
        
    )
    # Get Current UTC Timestamp
    $TimeStamp = (Get-Date).ToUniversalTime().ToString("MM-dd-yyyy HH:mm:ss")

    # Get Process and Thread IDs
    $ProcessID = [System.Diagnostics.Process]::GetCurrentProcess().Id
    $ThreadID = [System.Threading.Thread]::CurrentThread.ManagedThreadId

    # Format Log Entry (CMTrace Format)
    $LogEntry = "$TimeStamp`t$ProcessID`t$ThreadID`t$LogLevel`t$Component`t$Message"

    # Write to Log File in UTF-16 LE Encoding
    #$LogEntry | Out-File -FilePath $logFile  -Encoding Unicode -Append
}
Start-Transcript -Path $logFile -Append
Write-Log -Message "Starting Intellium EasyPrint installation" -Component INFO
Write-Log -Message "Finished Intellium EasyPrint installation" -Component INFO


Stop-Transcript