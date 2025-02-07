$EasyPrint = "$($env:ProgramFiles)\intellium EasyPrint\intelliumEasyPrint.exe"

if (Test-Path -Path $EasyPrint) {
    Write-Output 'Intellium EasyPrint installed.'
} else {
    Write-Output 'Intellium EasyPrint not installed'
}