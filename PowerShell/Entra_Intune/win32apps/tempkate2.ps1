# Set ErrorActionPreference to Stop for robust error handling.
$ErrorActionPreference = "Stop"

# Define the log folder and ensure it exists.
$logFolder = "$env:ProgramData\Microsoft\Logs"
if (!(Test-Path $logFolder)) {
    New-Item -ItemType Directory -Path $logFolder -Force | Out-Null
}

# Determine the directory where the script is located.
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path

# Search the current directory for an installer file (MSI or EXE).
$installerFiles = Get-ChildItem -Path $scriptDirectory -Filter "*.msi", "*.exe"
if ($installerFiles.Count -eq 0) {
    Write-Host "No installer found in the directory. Exiting..." -ForegroundColor Red
    exit 1
}
# Assume only one installer file exists.
$installerFile = $installerFiles[0]
$installerPath = $installerFile.FullName
$installerName = $installerFile.Name

# Define the log file name (e.g., Install-MyApp.msi.log or Install-MyApp.exe.log).
$logFile = Join-Path $logFolder "Install-$installerName.log"

# Custom logging function that writes log entries in a CMTrace/SCCM-compatible format.
function Write-LogEntry {
    param(
        [string]$Message,
        [string]$Severity = "INFO"  # Allowed values: INFO, WARNING, ERROR
    )
    $timestamp = Get-Date -Format "MM-dd-yyyy HH:mm:ss.fff"
    $entry = "[$timestamp] [$Severity] [InstallerScript] $Message"
    Add-Content -Path $logFile -Value $entry
    Write-Host $entry
}

# Log that the script has started.
Write-LogEntry "Script started. Searching for installer in $scriptDirectory."

# Log environment details.
$computerName = $env:COMPUTERNAME
$user = $env:USERNAME
$osInfo = (Get-CimInstance Win32_OperatingSystem).Caption
$uptime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$psVersion = $PSVersionTable.PSVersion.ToString()
Write-LogEntry "Environment Details: Computer Name: $computerName, User: $user, OS: $osInfo, Uptime: $uptime, PowerShell Version: $psVersion"

# Function to query Win32_Product for the installed version of the application.
function Get-InstalledAppVersion {
    param(
        [string]$AppName
    )
    try {
        $app = Get-WmiObject -Class Win32_Product -Filter "Name LIKE '%$AppName%'" -ErrorAction SilentlyContinue
        if ($app) {
            return $app.Version
        } else {
            return $null
        }
    } catch {
        return $null
    }
}

# Retrieve the installed application version (if any).
$installedVersion = Get-InstalledAppVersion -AppName $installerName

# Determine installer type and retrieve the installer version.
if ($installerFile.Extension -eq ".msi") {
    Write-LogEntry "Detected MSI installer: $installerName"
    # Attempt to retrieve the installer version from the registry's uninstall information.
    $uninstallKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    $msiInfo = Get-ItemProperty -Path $uninstallKey -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*$installerName*" }
    if ($msiInfo -and $msiInfo.DisplayVersion) {
        $installerVersion = $msiInfo.DisplayVersion
    } else {
        $installerVersion = "Unknown"
    }
    # Define the installation command for MSI.
    $installCmd = "msiexec.exe /i `"$installerPath`" /quiet /norestart /L*V `"$logFile`""
} elseif ($installerFile.Extension -eq ".exe") {
    Write-LogEntry "Detected EXE installer: $installerName"
    $installerVersion = "Unknown"
    # Define the installation command for EXE.
    $installCmd = "`"$installerPath`" /s /qn /log `"$logFile`""
} else {
    Write-LogEntry "Unsupported installer file type detected. Exiting." "ERROR"
    exit 1
}

# Log the version information.
if ($installedVersion) {
    Write-LogEntry "Installed version: $installedVersion"
} else {
    Write-LogEntry "No installed version detected."
}
Write-LogEntry "Installer version: $installerVersion"

# Compare the installed version with the installer version if possible.
if ($installedVersion -and $installerVersion -ne "Unknown") {
    try {
        $installedVerObj = [version]$installedVersion
        $installerVerObj = [version]$installerVersion
        if ($installedVerObj -ge $installerVerObj) {
            Write-LogEntry "Application is already up-to-date (Installed: $installedVersion, Installer: $installerVersion). Exiting." "INFO"
            exit 0
        } else {
            Write-LogEntry "A newer version is available. Upgrading application from $installedVersion to $installerVersion."
        }
    } catch {
        Write-LogEntry "Version comparison failed: $_" "WARNING"
        Write-LogEntry "Proceeding with installation."
    }
} else {
    Write-LogEntry "Either the application is not installed or the installer version is unknown. Proceeding with installation."
}

# Capture the start time of the installation.
$startTime = Get-Date

# Execute the installer via cmd.exe using Start-Process, waiting for completion.
Write-LogEntry "Starting installation of $installerName."
$process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c $installCmd" -NoNewWindow -Wait -PassThru

# Capture the end time and calculate the installation duration.
$endTime = Get-Date
$duration = New-TimeSpan -Start $startTime -End $endTime
Write-LogEntry "Installation duration: $($duration.ToString())"

# Check the exit code to determine success or failure.
if ($process.ExitCode -eq 0) {
    Write-LogEntry "Installation completed successfully." "INFO"
} else {
    Write-LogEntry "Installation failed with exit code $($process.ExitCode)." "ERROR"
}

# Log the completion of script execution.
Write-LogEntry "Script execution finished."
