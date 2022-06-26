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

        [int64]$CurrentObjectIndex = 0

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
                    Add-PsCommand -Command $CommandInfo.CommandInfo.Definition -CommandInfo $CommandInfo -PowershellInterface $ThisPowerShell
                }
                'Function' {
                    $ThisPowershell.AddScript($CommandInfo.CommandInfo.Definition)
                }
                'ScriptBlock' {
                    $ThisPowershell.AddScript($Command)
                }
                'ExternalScript' {
                    $ThisPowershell.AddScript($CommandInfo.ScriptBlock)
                }
                default {
                    # If the type is All, Application, Cmdlet, Configuration, Filter, or Script then run the command as-is
                    $ThisPowershell.AddStatement().AddCommand($Command)
                }

            }
        }
    }
}
