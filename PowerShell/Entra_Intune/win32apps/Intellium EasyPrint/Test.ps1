write-output $MyInvocation.MyCommand.Name
function test-function {
    Write-Output $MyInvocation.MyCommand.Name
}
test-function  