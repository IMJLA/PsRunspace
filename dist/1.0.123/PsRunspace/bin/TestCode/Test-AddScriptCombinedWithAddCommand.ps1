
$Command = 'Get-FolderAce'
$CommandDefinition = Get-Content -Path "E:\Owner\Documents\Google Drive\Programs\Scripts\PowerShell\PsNtfs\src\functions\public\$Command.ps1" -Raw


$PowerShellInterface = [powershell]::Create()
$null = $PowerShellInterface.AddScript($CommandDefinition)
$PowerShellInterface.Invoke()
$null = $PowerShellInterface.Commands.Clear()
$null = $PowerShellInterface.AddStatement().AddCommand($Command)
$null = $PowerShellInterface.AddParameter('LiteralPath', 'C:\Test')
$null = $PowerShellInterface.AddParameter('IncludeInherited')
$PowerShellInterface.Invoke()
$null = $PowerShellInterface.Dispose()
