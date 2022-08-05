function Convert-FromPsCommandInfoToString {
    param (
        [Parameter (
            Mandatory,
            Position = 0
        )]
        [PSCustomObject[]]$CommandInfo
    )
    process {
        ForEach ($ThisCmd in $CommandInfo) {

            switch ($ThisCmd.CommandType) {

                'Alias' {
                    # Resolve the alias to its command and start from the beginning with that command
                    $ThisCmd = Get-PsCommandInfo -Command $ThisCmd.CommandInfo.Definition
                    Convert-FromPsCommandInfoToString -CommandInfo $ThisCmd
                }
                'Function' {
                    "function $($ThisCmd.CommandInfo.Name) {`r`n$($ThisCmd.CommandInfo.Definition)`r`n}"
                }
                'ExternalScript' {
                    "$($ThisCmd.CommandInfo.ScriptBlock)"
                }
                'ScriptBlock' {
                    "$Command"
                }
                default {
                    "$Command"
                }

            }
        }
    }
}
