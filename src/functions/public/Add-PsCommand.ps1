function Add-PsCommand {

    <#
    .Synopsis
        Add a command to a [System.Management.Automation.PowerShell] instance

    .Description
        Used by Invoke-Thread
        Uses AddScript() or AddStatement() and AddCommand() depending on the command

    .EXAMPLE
        The following demonstrates sending a Cmdlet name to the -Command parameter
            [powershell]::Create() | AddCommand -Command 'Write-Output'
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
        [pscustomobject]$CommandInfo

    )

    begin {

        if ($CommandInfo -eq $null) {
            $CommandInfo = Get-PsCommandInfo -Command $Command
        }

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

                    # Recursively tokenize the command definition, identify Command tokens nested within, and get their definitions
                    $CommandsToAdd = Get-NestedCommandInfo -PsCommandInfo $CommandInfo

                    # Add the definitions of those functions if available
                    # TODO: Add modules if available? Not needed at this time but maybe later
                    ForEach ($ThisCommandInfo in $CommandsToAdd) {
                        if ($ThisCommandInfo.CommandType -eq [System.Management.Automation.CommandTypes]::Function) {
                            [string]$ThisFunction = "function $($ThisCommandInfo.CommandInfo.Name) {`r`n$($ThisCommandInfo.CommandInfo.Definition)`r`n}"
                            $null = $ThisPowershell.AddScript($ThisFunction)
                        }
                    }

                }
                'ScriptBlock' {
                    $null = $ThisPowershell.AddScript($Command)
                }
                'ExternalScript' {
                    $null = $ThisPowershell.AddScript($CommandInfo.ScriptBlock)
                }
                default {
                    # If the type is All, Application, Cmdlet, Configuration, Filter, or Script then run the command as-is
                    $null = $ThisPowershell.AddStatement().AddCommand($Command)
                }

            }
        }
    }
}
