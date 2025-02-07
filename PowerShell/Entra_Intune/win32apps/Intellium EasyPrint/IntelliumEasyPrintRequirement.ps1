$EasyPrint = "$($env:ProgramFiles)\intellium EasyPrint\intelliumEasyPrint.exe"

if(Test-Path -Path $EasyPrint)
{
    Write-Output 'Intellium EasyPrint found.'
}
else 
{
Write-Output 'Intellium EasyPrint not found'
}