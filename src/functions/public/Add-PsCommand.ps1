function Add-PsCommand {

    <#
    .Synopsis
        Add a command to a [System.Management.Automation.PowerShell] instance
    .Description
        Used by Invoke-Thread
        Uses AddScript() or AddStatement() and AddCommand() depending on the command
    .EXAMPLE
        [powershell]::Create() | Add-PsCommand -Command 'Write-Output'

        Add a command by sending a Cmdlet name to the -Command parameter
    #>

    param(

        # Powershell interface to add the Command to
        [Parameter(ValueFromPipeline = $true)]
        [powershell[]]$PowershellInterface,

        <#
        Command to add to the Powershell interface
        This can be a scriptblock object, or a string that specifies a:
            Alias
            Function (the name of the function)
            ExternalScript (the path to the .ps1 file)
            All, Application, Cmdlet, Configuration, Filter, or Script
        #>
        [Parameter(Position = 0)]
        $Command,

        # Output from Get-PsCommandInfo
        # Optional, to improve performance if it will be re-used for multiple calls of Add-PsCommand
        [pscustomobject]$CommandInfo,

        # Add Commands rather than their definitions
        [switch]$Force

    )

    begin {

        if ($CommandInfo -eq $null) {
            $CommandInfo = Get-PsCommandInfo -Command $Command
        }

        $TodaysHostname = HOSTNAME.EXE

    }
    process {

        ForEach ($ThisPowershell in $PowershellInterface) {

            switch ($CommandInfo.CommandType) {

                'Alias' {
                    # Resolve the alias to its command and start from the beginning with that command.
                    $CommandInfo = Get-PsCommandInfo -Command $CommandInfo.CommandInfo.Definition
                    $null = Add-PsCommand -Command $CommandInfo.CommandInfo.Definition -CommandInfo $CommandInfo -PowershellInterface $ThisPowerShell
                }
                'Function' {

                    if ($Force) {
                        <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "Add-PsCommand adding command '$Command' of type '$($CommandInfo.CommandType)'"
                        # If the type is All, Application, Cmdlet, Configuration, Filter, or Script then run the command as-is
                        Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tAdd-PsCommand`t`$PowershellInterface.AddStatement().AddCommand('$Command')"
                        $null = $ThisPowershell.AddStatement().AddCommand($Command)
                    } else {
                        # Add the definitions of the function
                        # BUG: Look at the definition of Get-Member for example, it is not in a ScriptModule so its definition is not PowerShell code
                        [string]$ThisFunction = "function $($CommandInfo.CommandInfo.Name) {`r`n$($CommandInfo.CommandInfo.Definition)`r`n}"
                        <#NormallyCommentThisForPerformanceOptimization#>##Write-Debug "Add-PsCommand adding Script (the Definition of a Function)"
                        Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tAdd-PsCommand`t`$PowershellInterface.AddScript('function $($CommandInfo.CommandInfo.Name) {...}') # Function definition not expanded in debug message for brevity"
                        $null = $ThisPowershell.AddScript($ThisFunction)
                    }
                }
                'ExternalScript' {
                    <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "Add-PsCommand adding Script (the ScriptBlock of an ExternalScript)"
                    Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tAdd-PsCommand`t`$PowershellInterface.AddScript(`"$($CommandInfo.ScriptBlock)`") # `$CommandInfo.ScriptBlock not expanded in debug message for brevity"
                    $null = $ThisPowershell.AddScript($CommandInfo.ScriptBlock)
                }
                'ScriptBlock' {
                    <#NormallyCommentThisForPerformanceOptimization#>###Write-Debug "Add-PsCommand adding Script (a ScriptBlock)"
                    <#NormallyCommentThisForPerformanceOptimization#>##Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tAdd-PsCommand`t`$PowershellInterface.AddScript('$Command')"
                    Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tAdd-PsCommand`t`$PowershellInterface.AddScript(`"`$Command`") # `$Command variable not expanded in debug message for brevity"
                    $null = $ThisPowershell.AddScript($Command)
                }
                default {
                    Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tAdd-PsCommand`t# Adding command '$Command' of type '$($CommandInfo.CommandType)'"
                    # If the type is All, Application, Cmdlet, Configuration, Filter, or Script then run the command as-is
                    Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tAdd-PsCommand`t`$PowershellInterface.AddStatement().AddCommand('$Command')"
                    $null = $ThisPowershell.AddStatement().AddCommand($Command)
                }

            }
        }
    }
}
