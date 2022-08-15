function Convert-FromPsCommandInfoToString {
    param (
        [Parameter (
            Mandatory,
            Position = 0
        )]
        [PSCustomObject[]]$CommandInfo,

        # Will be sent to the Type parameter of Write-LogMsg in the PsLogMessage module
        [string]$DebugOutputStream = 'Silent',

        [string]$TodaysHostname = (HOSTNAME.EXE)

    )
    process {
        ForEach ($ThisCmd in $CommandInfo) {

            switch ($ThisCmd.CommandType) {

                'Alias' {
                    # Resolve the alias to its command and start from the beginning with that command
                    $ThisCmd = Get-PsCommandInfo -Command $ThisCmd.CommandInfo.Definition -DebugOutputStream $DebugOutputStream -TodaysHostname $TodaysHostname
                    Convert-FromPsCommandInfoToString -CommandInfo $ThisCmd -DebugOutputStream $DebugOutputStream -TodaysHostname $TodaysHostname
                }
                'Function' {
                    "function $($ThisCmd.CommandInfo.Name) {`r`n$($ThisCmd.CommandInfo.Definition)`r`n}"
                }
                'ExternalScript' {
                    "$($ThisCmd.ScriptBlock)"
                    #"$($ThisCmd.CommandInfo.ScriptBlock)"
                    #"$Command"
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
