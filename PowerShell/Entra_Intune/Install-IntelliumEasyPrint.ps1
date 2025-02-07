# Define Log location
$LogPath = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs"

# Ensure Log Directory Exists
if (!(Test-Path $LogPath)) {
    New-Item -Path $LogPath -ItemType Directory -Force
}

Start-Transcript -Path (Join-Path $LogPath 'Intellium_EasyPrint.log') -Append

# Define application details
$ApplicationBinary = 'intellium_EasyPrint_4.28.10.exe'
$ApplicationName = 'Intellium_EasyPrint'
$ApplicationPath = "$env:ProgramFiles\Intellium EasyPrint\IntelliumEasyPrint.exe"

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
        ArgumentList = @("/SP-", "/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART")
        NoNewWindow  = $true
        Wait         = $true
    }
    try {
        Write-Output "Starting installation of: $ApplicationName..."
        Start-Process @ApplicationParams -ErrorAction Stop
        Write-Output "Installation completed successfully: $ApplicationName"
    } catch {
        Write-Output "Error occurred during installation: $_"
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
            Write-Output "Firewall rule ($Protocol) installed successfully: $FirewallRuleName"
        } catch {
            Write-Output "Error occurred while adding firewall rule ($Protocol): $_"
        }
    }
}

# Main Execution Logic
if (-not (Test-ApplicationExists)) {
    Write-Output "Application not found: $ApplicationName. Installing..."
    Install-Application
}

# **Check again if the application is installed before adding firewall rules**
if (Test-ApplicationExists) {
    Write-Output "Application installed: $ApplicationName. Checking Firewall Rules..."

    if (-not (Test-FirewallRuleExists)) {
        Write-Output "Firewall rules missing. Adding Firewall rules for TCP and UDP: $FirewallRuleName"
        New-FirewallRule
    } else {
        Write-Output "Firewall rules already exist: $FirewallRuleName"
    }
} else {
    Write-Output "Application installation failed or application not found. Skipping firewall rule creation."
}

Stop-Transcript
