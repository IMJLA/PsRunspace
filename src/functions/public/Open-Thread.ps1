function Open-Thread {

    <#
    .Synopsis
        Prepares each thread so it is ready to execute a command and capture the output streams

    .Description
        Used by Split-Thread

        For each InputObject an instance will be created of [System.Management.Automation.PowerShell]
        Then a series of commands will be run to enable the specified output streams (all by default)
    #>

    Param(

        # Objects to pass to the Command as an argument or parameter
        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        $InputObject,

        # .Net Framework runspace pool to use for the threads
        [Parameter(
            Mandatory = $true
        )]
        [System.Management.Automation.Runspaces.RunspacePool]$RunspacePool,

        <#
        Name of a property (whose value is a string) that exists on each $InputObject
        It will be used to represent the object in text form
        If left null, the object's ToString() method will be used instead.
        #>
        [string]$ObjectStringProperty,

        # PowerShell Command or Script to run against each InputObject
        [Parameter(Mandatory = $true)]
        $Command,

        # Output from Get-PsCommandInfo
        [pscustomobject[]]$CommandInfo,

        # Named parameter of the Command to pass InputObject to
        # If this is not specified, InputObject will be passed to the Command as an argument
        [string]$InputParameter = $null,

        <#
        Parameters to add to the Command
        Each parameter is a name-value pair in the hashtable:
            @{"ParameterName" = "Value"}
            @{"ParameterName" = "Value" ; "ParameterTwo" = "Value2"}
        #>
        [HashTable]$AddParam = @{},

        # Switches to add to the Command
        [string[]]$AddSwitch = @(),

        # Will be sent to the Type parameter of Write-LogMsg in the PsLogMessage module
        [string]$DebugOutputStream = 'Silent',

        # Hostname to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$TodaysHostname = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Log messages which have not yet been written to disk
        [hashtable]$LogBuffer = $Global:LogMessages,

        # ID of the parent progress bar under which to show progres
        [int]$ProgressParentId

    )

    begin {

        $Progress = @{
            Activity = "Open-Thread -Command '$Command'"
        }
        if ($PSBoundParameters.ContainsKey('ProgressParentId')) {
            $Progress['ParentId'] = $ProgressParentId
            $Progress['Id'] = $ProgressParentId + 1
        } else {
            $Progress['Id'] = 0
        }

        $LogParams = @{
            Buffer       = $LogBuffer
            ThisHostname = $TodaysHostname
            Type         = $DebugOutputStream
            WhoAmI       = $WhoAmI
        }

        $CommandInfoParams = @{
            DebugOutputStream = $DebugOutputStream
            TodaysHostname    = $TodaysHostname
            WhoAmI            = $WhoAmI
            LogBuffer         = $LogBuffer
        }

        [int64]$CurrentObjectIndex = 0
        $ThreadCount = @($InputObject).Count
        Write-LogMsg @LogParams -Text " # Received $(($CommandInfo | Measure-Object).Count) PsCommandInfos from Split-Thread for '$Command'"

        if ($CommandInfo) {

            # Begin to build the command that the script will run with all its parameters
            if (Test-Path $Command -ErrorAction SilentlyContinue) {
                # If $Command is a valid file path, dot-source it and wrap it in single quotes to handle spaces
                $CommandStringForScriptDefinition = [System.Text.StringBuilder]::new(". '$Command'")
            } else {
                $CommandStringForScriptDefinition = [System.Text.StringBuilder]::new($Command)
            }

            # Build the param block of the script. Along the way, add any necessary parameters and switches
            # Avoided using AppendJoin. It would provide slight performance and code readability but lacks support in PS 5.1
            $ScriptDefinition = [System.Text.StringBuilder]::new()
            $null = $ScriptDefinition.AppendLine('param (')
            If ([string]::IsNullOrEmpty($InputParameter)) {
                $null = $ScriptDefinition.Append("    `$PsRunspaceArgument1")
                $null = $CommandStringForScriptDefinition.Append(" `$PsRunspaceArgument1")
            } else {
                $null = $ScriptDefinition.Append("    `$$InputParameter")
                $null = $CommandStringForScriptDefinition.Append(" -$InputParameter `$$InputParameter")
            }

            ForEach ($ThisKey in $AddParam.Keys) {
                $null = $ScriptDefinition.Append(",`r`n    `$$ThisKey")
                $null = $CommandStringForScriptDefinition.Append(" -$ThisKey `$$ThisKey")
            }

            ForEach ($ThisSwitch in $AddSwitch) {
                $null = $ScriptDefinition.Append(",`r`n    [switch]`$", $ThisSwitch)
                $null = $CommandStringForScriptDefinition.Append(" -$ThisSwitch")
            }
            $null = $ScriptDefinition.AppendLine("`r`n)`r`n")

            # Define the command in the script ($Command)
            Convert-FromPsCommandInfoToString @CommandInfoParams -CommandInfo $CommandInfo |
            ForEach-Object {
                $null = $ScriptDefinition.AppendLine("`r`n$_")
            }
            $null = $ScriptDefinition.AppendLine()

            # Call the function in the script
            Write-LogMsg @LogParams -Text " # Command string is $($CommandStringForScriptDefinition.ToString())"
            $CommandStringForScriptDefinition |
            ForEach-Object {
                $null = $ScriptDefinition.AppendLine("`r`n$_")
            }
            $null = $ScriptDefinition.AppendLine()

            # Convert the script to a single string
            $ScriptString = $ScriptDefinition.ToString()

            # Remove blank lines
            # Commented out due to risk of unintended side effects: what if the code includes a here-string that requires blank lines, etc)
            #while ( $ScriptString -match '\r\n\r\n' ) {
            #    $ScriptString = $ScriptString -replace "`r`n`r`n", "`r`n"
            #}

            # Convert the script to a single scriptblock
            $ScriptBlock = [scriptblock]::Create($ScriptString)
        }

    }
    process {

        ForEach ($Object in $InputObject) {

            $CurrentObjectIndex++

            if ($ObjectStringProperty -ne '') {
                [string]$ObjectString = $Object."$ObjectStringProperty"
            } else {
                [string]$ObjectString = $Object.ToString()
            }

            Write-LogMsg @LogParams -Text "`$PowershellInterface = [powershell]::Create() # for '$Command' on '$ObjectString'"
            $PowershellInterface = [powershell]::Create()

            Write-LogMsg @LogParams -Text "`$PowershellInterface.RunspacePool = `$RunspacePool # for '$Command' on '$ObjectString'"
            $PowershellInterface.RunspacePool = $RunspacePool

            # Do I need this one?  What commands would be in there?
            Write-LogMsg @LogParams -Text "`$PowershellInterface.Commands.Clear() # for '$Command' on '$ObjectString'"
            $null = $PowershellInterface.Commands.Clear()

            if ($ScriptBlock) {
                $null = Add-PsCommand @CommandInfoParams -Command $ScriptBlock -PowershellInterface $PowershellInterface #-DebugOutputStream 'Debug'

                <#
                If:
                    the Command is a ScriptBlock (such as the content of a .ps1 file)
                    and
                    $InputParameter is null
                Then:
                    Pass $Object into the runspace as a parameter (not an argument)
                Otherwise we will:
                    Pass $Object into the runspace as an argument
                Because:
                    This allows more flexibility in the ScriptBlock
                    TODO: Need more detail here, this was a bugfix for .ps1 files but I didn't save the details (or maybe I did and forgot)
                #>
                If ([string]::IsNullOrEmpty($InputParameter)) {
                    $InputParameter = 'PsRunspaceArgument1'
                }
            } else {
                $null = Add-PsCommand @CommandInfoParams -Command $Command -CommandInfo $CommandInfo -PowershellInterface $PowershellInterface -Force
            }

            # Prepare to
            # Do this even if we end up passing it as an argument to the command inside the runspace
            ## WHY?? past self did not explain this and it's causing problems for non-script values of Command
            ## Therefore I have re-introduced AddArgument until I figure out what was wrong with it #
            If ([string]::IsNullOrEmpty($InputParameter)) {
                Write-LogMsg @LogParams -Text "`$PowershellInterface.AddArgument('$ObjectString') # for '$Command' on '$ObjectString'"
                $null = $PowershellInterface.AddArgument($Object)
                <#NormallyCommentThisForPerformanceOptimization#>$InputParameterStringForDebug = " '$ObjectString'"
            } else {
                Write-LogMsg @LogParams -Text "`$PowershellInterface.AddParameter('$InputParameter', '$ObjectString') # for '$Command' on '$ObjectString'"
                $null = $PowershellInterface.AddParameter($InputParameter, $Object)
                <#NormallyCommentThisForPerformanceOptimization#>$InputParameterStringForDebug = "-$InputParameter '$ObjectString'"
            }

            $AdditionalParameters = @()
            $AdditionalParameters = ForEach ($Key in $AddParam.Keys) {
                Write-LogMsg @LogParams -Text "`$PowershellInterface.AddParameter('$Key', '$($AddParam.$key)') # for '$Command' on '$ObjectString'"
                $null = $PowershellInterface.AddParameter($Key, $AddParam.$key)
                <#NormallyCommentThisForPerformanceOptimization#>"-$Key '$($AddParam.$key)'"
            }

            $Switches = @()
            $Switches = ForEach ($Switch in $AddSwitch) {
                Write-LogMsg @LogParams -Text "`$PowershellInterface.AddParameter('$Switch') # for '$Command' on '$ObjectString'"
                $null = $PowershellInterface.AddParameter($Switch)
                <#NormallyCommentThisForPerformanceOptimization#>"-$Switch"
            }


            $NewPercentComplete = $CurrentObjectIndex / $ThreadCount * 100
            if (($NewPercentComplete - $OldPercentComplete) -ge 1) {
                $OldPercentComplete = $NewPercentComplete
                $AdditionalParametersString = $AdditionalParameters -join ' '
                $SwitchParameterString = $Switches -join ' '

                $StatusString = "Invoking thread $CurrentObjectIndex`: $Command $InputParameterStringForDebug $AdditionalParametersString $SwitchParameterString"
                $Status = "$([int]$NewPercentComplete)% ($($ThreadCount - $CurrentObjectIndex) of $ThreadCount remain)"
                Write-Progress @Progress -CurrentOperation $StatusString -PercentComplete $NewPercentComplete -Status $Status
            }

            Write-LogMsg @LogParams -Text "`$Handle = `$PowershellInterface.BeginInvoke() # for '$Command' on '$ObjectString'"
            $Handle = $PowershellInterface.BeginInvoke()

            [PSCustomObject]@{
                Handle              = $Handle
                PowerShellInterface = $PowershellInterface
                Object              = $Object
                ObjectString        = $ObjectString
                Index               = $CurrentObjectIndex
                Command             = "$Command"
            }

        }

    }

    end {

        Write-Progress @Progress -Completed

    }

}
