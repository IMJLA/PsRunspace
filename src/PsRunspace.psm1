
<#
# Dot source any functions
ForEach ($ThisScript in $ScriptFiles) {
    # Dot source the function
    . $($ThisScript.FullName)
}
#>
Export-ModuleMember -Function @('Add-PsCommand','Get-PsCommandInfo','Open-Thread','Split-Thread','Wait-Thread')

