function Write-SCCMLog {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $true)]
        [string]$Component,

        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "VERBOSE")]
        [string]$LogLevel = "INFO",

        [Parameter(Mandatory = $false)]
        [string]$LogFile = "C:\Windows\Temp\SCCMLog.log"
    )

    # Define Log Level Codes (Matching SCCM CMTrace)
    $LogLevelCodes = @{
        "INFO"    = 1
        "WARNING" = 2
        "ERROR"   = 3
        "VERBOSE" = 4
    }

    # Get Current UTC Timestamp
    $TimeStamp = (Get-Date).ToUniversalTime().ToString("MM-dd-yyyy HH:mm:ss.fff")

    # Get Process and Thread IDs
    $ProcessID = [System.Diagnostics.Process]::GetCurrentProcess().Id
    $ThreadID = [System.Threading.Thread]::CurrentThread.ManagedThreadId

    # Format Log Entry (CMTrace Format)
    $LogEntry = "$TimeStamp`t$ProcessID`t$ThreadID`t$LogLevel`t$Component`t$Message"

    # Write to Log File in UTF-16 LE Encoding
    $LogEntry | Out-File -FilePath $LogFile -Encoding Unicode -Append
}

# Example Usage:
Write-SCCMLog -Message "Application installed successfully." -Component "Software Deployment" -LogLevel "INFO"
Write-SCCMLog -Message "Disk space low." -Component "Health Check" -LogLevel "WARNING"
Write-SCCMLog -Message "Failed to connect to database." -Component "Database Connector" -LogLevel "ERROR"
