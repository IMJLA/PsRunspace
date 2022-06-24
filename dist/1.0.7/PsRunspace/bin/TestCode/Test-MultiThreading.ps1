﻿Remove-Module PsRunspace -ErrorAction SilentlyContinue *> $null
Import-Module $PSScriptRoot\..\..\src\PsRunspace.psm1 *> $null

#[string]$Folder = 'C:\Test'
#$Samples = Get-ChildItem -Path $Folder -Recurse | Select -ExpandProperty FullName
$Samples = 1..10
$Count = ($Samples | Measure-Object).Count

#$Command = "Write-Output"
#$Command = [scriptblock]::create("Write-Output `$args[0]")
#$Command = "$PSScriptRoot\Test-Command.ps1"

Remove-Module TestModule -ErrorAction SilentlyContinue *> $null
Import-Module $PSScriptRoot\TestModule.psm1 *> $null
$Command = "Test-Function"

$Start = Get-Date
$Samples | ForEach-Object {
    & $Command $_
}
$End = Get-Date
$Elapsed3 = New-TimeSpan -Start $Start -End $End

$Start = Get-Date
$Samples | Split-Thread -Command $Command
$End = Get-Date
$Elapsed = New-TimeSpan -Start $Start -End $End

$Start = Get-Date
$Samples | Split-Thread -Command $Command -OutputStream All
$End = Get-Date
$Elapsed2 = New-TimeSpan -Start $Start -End $End


" "
"Multithreading benefit are even more significant with long-running operations"
"These operations each generated 5 output streams then slept for 1 second to simulate a long-running operation"
"$($Elapsed3.TotalSeconds) seconds for ForEach-Object for $Count objects"
"$($Elapsed.TotalSeconds) seconds for Split-Thread for $Count objects"
"$($Elapsed2.TotalSeconds) seconds for Split-Thread -OutputStream All for $Count objects"