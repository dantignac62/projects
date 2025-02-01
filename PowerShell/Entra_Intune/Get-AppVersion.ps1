# Define the path to the application executable
$exePath = "C:\Program Files (x86)\DYMO\DYMO Connect\DYMOConnect.exe"

# Define the expected version
$expectedVersion = "1.4.7.48"  # Update with the correct version

# Check if the file exists
if (Test-Path $exePath) {
    # Get the file version
    $fileVersion = (Get-Item $exePath).VersiosLAURAnInfo.FileVersion

    # Compare with expected version
    if ($fileVersion -eq $expectedVersion) {
        exit 0  # Success, app is installed
    } else {
        exit 1  # Failure, app is installed but wrong version
    }
} else {
        exit 1  # Failure, app is not installed
}
