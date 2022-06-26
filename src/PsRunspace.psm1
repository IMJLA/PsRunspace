
$ScriptFiles = Get-ChildItem -Path "$PSScriptRoot\*.ps1" -Recurse | Where-Object -FilterScript {
    $_.PSParentPath -notlike "*\bin\*"
}

Write-Debug "$(($ScriptFiles | Measure-Object).Count) .ps1 files found in folder '$PSScriptRoot'"


# Dot source any functions
ForEach ($ThisScript in $ScriptFiles) {
    # Dot source the function
    . $($ThisScript.FullName)
}

# Add any custom C# classes as usable (exported) types
$CSharpFiles = Get-ChildItem -Path "$PSScriptRoot\*.cs"
ForEach ($ThisFile in $CSharpFiles) {
    Add-Type -Path $ThisFile.FullName -ErrorAction Stop
}

# Export any public functions
$PublicScriptFiles = $ScriptFiles | Where-Object -FilterScript {
    ($_.PSParentPath | Split-Path -Leaf) -eq 'public'
}
$publicFunctions = $PublicScriptFiles.BaseName
Export-ModuleMember -Function @('Add-PsCommand','Get-PsCommandInfo','Open-Thread','Split-Thread','Wait-Thread')















