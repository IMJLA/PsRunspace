function Get-PsCommandInfo {

    <#
    .Synopsis
        Get info about a PowerShell command

    .Description
        Used by Split-Thread, Invoke-Thread, and Add-PsCommand

       Determine whether the Command is a [System.Management.Automation.ScriptBlock] object
       If not, passes it to the Name parameter of Get-Command

    .EXAMPLE
        The following demonstrates sending a Cmdlet name to the -Command parameter
            Get-PsCommandInfo -Command 'Write-Output'
    #>

    param(
        <#
        Command to retrieve info on
        This can be a scriptblock object, or a string that specifies an:
            Alias
            Function (the name of the function)
            ExternalScript (the path to the .ps1 file)
            All, Application, Cmdlet, Configuration, Filter, or Script
        #>
        $Command

    )

    if ($Command.GetType().FullName -eq 'System.Management.Automation.ScriptBlock') {
        $CommandType = 'ScriptBlock'
    } else {
        $CommandInfo = Get-Command $Command -ErrorAction SilentlyContinue
        $CommandType = $CommandInfo.CommandType
        if ($CommandInfo.Source) {
            $ModuleInfo = Get-Module -Name $CommandInfo.Source -ErrorAction SilentlyContinue
        }
    }

    #CommentedForPerformanceOptimization#Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGet-PsCommandInfo`t$Command is a $CommandType"
    [pscustomobject]@{
        CommandInfo            = $CommandInfo
        ModuleInfo             = $ModuleInfo
        CommandType            = $CommandType
        SourceModuleDefinition = $ModuleInfo.Definition
        SourceModuleName       = $CommandInfo.Source
    }

}
