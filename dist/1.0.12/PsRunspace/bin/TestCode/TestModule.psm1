Function Test-Function { Test-Subfunction $args[0] }

Function Test-Subfunction {
    Write-Host "Host: $($args[0])"
    Write-Debug $args[0]
    Write-Information "Info: $($args[0])"
    Write-Output "Output: $($args[0])"
    Write-Verbose $args[0]
    Write-Warning $args[0]
    Start-Sleep -Seconds 1

    #Write-Progress -Activity 'activity' -Status 'status' -PercentComplete 50 -CurrentOperation 'currentoperation'
}
