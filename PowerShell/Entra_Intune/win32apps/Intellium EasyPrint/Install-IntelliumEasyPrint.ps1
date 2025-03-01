# Define application details
$ApplicationBinary = 'intellium_EasyPrint_4.28.10.exe'
$ApplicationName = 'Intellium_EasyPrint'
$ApplicationPath = "$env:ProgramFiles\Intellium EasyPrint\IntelliumEasyPrint.exe"

# Define Log location
$appName = 'IntelliumEasyPrint'
$logPath = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs"
$logFile = Join-Path -Path ([System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)) -ChildPath '.log'
$appLogFile = Join-Path -Path $logPath -ChildPath "$appName.log"
# Ensure Log Directory Exists
if (!(Test-Path $LogPath)) {
    New-Item -Path $LogPath -ItemType Directory -Force
}
function Write-SCCMLog {
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

    # Define Log Level Codes (Matching SCCM CMTrace)
    <#$LogLevelCodes = @{
        "INFO"    = 1
        "WARNING" = 2
        "ERROR"   = 3
        "VERBOSE" = 4
    }#>

    # Get Current UTC Timestamp
    $TimeStamp = (Get-Date).ToUniversalTime().ToString("MM-dd-yyyy HH:mm:ss")    # Get Process and Thread IDs
    $ProcessID = [System.Diagnostics.Process]::GetCurrentProcess().Id
    $ThreadID = [System.Threading.Thread]::CurrentThread.ManagedThreadId

    # Format Log Entry (CMTrace Format)
    $LogEntry = "$TimeStamp`t$ProcessID`t$ThreadID`t$LogLevel`t$Component`t$Message"

    # Write to Log File in UTF-16 LE Encoding
    $LogEntry | Out-File -FilePath $logFile  -Encoding Unicode -Append
}

#Start-Transcript -Path $logFile -Append

# Define Firewall rule name 
$FirewallRuleName = 'IntelliumEasyPrint'

# Determine if application exists
function Test-ApplicationExists { 
    return (Test-Path -Path $ApplicationPath)
}

# Determine if Firewall rule exists
function Test-FirewallRuleExists {
    return ($null -ne (Get-NetFirewallRule -DisplayName $FirewallRuleName -ErrorAction SilentlyContinue))
}

# Install the application
function Install-Application {
    $ApplicationBinaryPath = "$PSScriptRoot\$ApplicationBinary"  # Use script location
    $ApplicationParams = @{
        FilePath     = $ApplicationBinaryPath
        ArgumentList = @("/SP-", "/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART", "/LOG=")
        NoNewWindow  = $true
        Wait         = $true
    }
    try {
        Write-SCCMLog -Message "Starting installation of: $ApplicationName..." -LogLevel INFOget
        Start-Process @ApplicationParams -ErrorAction Stop
        Write-SCCMLog -Message "Installation completed successfully: $ApplicationName" -LogLevel INFO
    } catch {
        Write-SCCMLog -Message "Error occurred during installation: $_" -LogLevel ERROR
    }
}

# Create both TCP and UDP Firewall Rules
function New-FirewallRule {
    $Protocols = @("TCP", "UDP")
    foreach ($Protocol in $Protocols) {
        $FirewallRuleParams = @{
            DisplayName = $FirewallRuleName
            Protocol    = $Protocol
            Profile     = @("Private", "Public")
            Enabled     = "True"
            Action      = "Allow"
            Program     = $ApplicationPath
        }
        try {
            New-NetFirewallRule @FirewallRuleParams -ErrorAction Stop
            Write-SCCMLog -Message "Firewall rule ($Protocol) installed successfully: $FirewallRuleName" -LogLevel INFO
        } catch {
            Write-SCCMLog -Message "Error occurred while adding firewall rule ($Protocol): $_" -LogLevel ERROR
        }
    }
}

# Main Execution Logic
if (-not (Test-ApplicationExists)) {
    Write-SCCMLog -Message "Application not found: $ApplicationName. Installing..."  -LogLevel INFO
    Install-Application
}

# **Check again if the application is installed before adding firewall rules**
if (Test-ApplicationExists) {
    Write-SCCMLog -Message "Application installed: $ApplicationName. Checking Firewall Rules..." -LogLevel INFO

    if (-not (Test-FirewallRuleExists)) {
        Write-SCCMLog -Message "Firewall rules missing. Adding Firewall rules for TCP and UDP: $FirewallRuleName" -LogLevel INFO
        New-FirewallRule
    } else {
        Write-SCCMLog -Message "Firewall rules already exist: $FirewallRuleName" -LogLevel INFO
    }
} else {
    Write-SCCMLog -Message "Application installation failed or application not found. Skipping firewall rule creation." -LogLevel INFO
}

#Stop-Transcript
