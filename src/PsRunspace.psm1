<#
# Dot source any functions
ForEach ($ThisScript in $ScriptFiles) {
    # Dot source the function
    . $($ThisScript.FullName)
}
#>
Import-Module PsLogMessage -ErrorAction SilentlyContinue
Export-ModuleMember -Function @('Add-PsCommand','Add-PsModule','Convert-FromPsCommandInfoToString','Expand-PsCommandInfo','Expand-PsToken','Get-PsCommandInfo','Open-Thread','Split-Thread','Wait-Thread')











