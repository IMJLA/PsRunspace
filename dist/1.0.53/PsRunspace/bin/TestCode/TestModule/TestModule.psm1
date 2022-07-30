Function Test-Function {
    Write-Host "Host: Parent Function - $($args[0])"
    Write-Debug "  Parent Function - $($args[0])"
    Write-Information "Info: Parent Function - $($args[0])"
    Write-Output "Output: Parent Function - $($args[0])"
    Write-Verbose "Parent Function - $($args[0])"
    Write-Warning "Parent Function - $($args[0])"
    Start-Sleep -Seconds 1
    Test-Subfunction $args[0]
}

Function Test-Subfunction {
    Write-Host "Host: Child Function - $($args[0])"
    Write-Debug "  Child Function - $($args[0])"
    Write-Information "Info: Child Function - $($args[0])"
    Write-Output "Output: Child Function - $($args[0])"
    Write-Verbose "Child Function - $($args[0])"
    Write-Warning "Child Function - $($args[0])"
    Start-Sleep -Seconds 1

    #Write-Progress -Activity 'activity' -Status 'status' -PercentComplete 50 -CurrentOperation 'currentoperation'
}
