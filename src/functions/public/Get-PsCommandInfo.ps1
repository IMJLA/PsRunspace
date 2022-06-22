function Get-PsCommandInfo {

    <#
    .Synopsis
        Get info about a PowerShell command

    .Description
        Used by Split-Thread, Invoke-Thread, and Add-PsCommand

       Determine whether the Command is a [System.Management.Automation.ScriptBlock] object
       If not, passes it to the Name parameter of Get-Command to retrieve info about the command, its definition, and its source module

    .EXAMPLE
        The following demonstrates sending a Cmdlet name to the -Command parameter
            Get-PsCommandInfo -Command 'Write-Output'
    #>

    param(

        # Command to retrieve info on
        $Command

    )

    if ($Command.GetType().FullName -eq 'System.Management.Automation.ScriptBlock') {
        $CommandType = 'ScriptBlock'
    } else {
        $CommandInfo = Get-Command $Command -ErrorAction SilentlyContinue
        $CommandType = $CommandInfo.CommandType
        if ($CommandType -eq 'Function') {
            if ($CommandInfo.Source) {
                $SourceModuleDefinition = (Get-Module -Name $CommandInfo.Source).Definition
            }
        } else {
            $SourceModuleName = $CommandInfo.Source
        }
    }

    #CommentedForPerformanceOptimization#Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGet-PsCommandInfo`t$Command is a $CommandType"
    [pscustomobject]@{
        CommandInfo            = $CommandInfo
        CommandType            = $CommandType
        SourceModuleDefinition = $SourceModuleDefinition
        SourceModuleName       = $SourceModuleName
    }

}
