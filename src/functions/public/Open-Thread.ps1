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
        [string[]]$AddSwitch = @()

    )

    begin {

        [int64]$CurrentObjectIndex = 0
        $ThreadCount = @($InputObject).Count
        Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tOpen-Thread`t# Received $(($CommandInfo | Measure-Object).Count) PsCommandInfos from Split-Thread for '$Command'"

    }
    process {

        ForEach ($Object in $InputObject) {

            $CurrentObjectIndex++

            if ($ObjectStringProperty -ne '') {
                [string]$ObjectString = $Object."$ObjectStringProperty"
            } else {
                [string]$ObjectString = $Object.ToString()
            }

            Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tOpen-Thread`t`$PowershellInterface = [powershell]::Create() # for '$Command' on '$ObjectString'"
            $PowershellInterface = [powershell]::Create()

            Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tOpen-Thread`t`$PowershellInterface.RunspacePool = `$RunspacePool # for '$Command' on '$ObjectString'"
            $PowershellInterface.RunspacePool = $RunspacePool

            # Do I need this one?  What commands would be in there?
            Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tOpen-Thread`t`$PowershellInterface.Commands.Clear() # for '$Command' on '$ObjectString'"
            $null = $PowershellInterface.Commands.Clear()

            ######ForEach ($ThisCommandInfo in $CommandInfo) {
            ######    $null = Add-PsCommand -Command $ThisCommandInfo.CommandInfo.Name -CommandInfo $ThisCommandInfo -PowershellInterface $PowershellInterface
            ######}
            if ($CommandInfo) {
                <#
                #TODO: This inefficiently waits for each to finish before beginning the next.
                #      Rework to break out of this function after only BeginInboke for each thread, and use Wait-Thread with Dispose set to false
                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tOpen-Thread`t`$Handle = `$PowershellInterface.BeginInvoke() # to preload command definitions for '$ObjectString'"
                $Handle = $PowershellInterface.BeginInvoke()
                while ($Handle.IsCompleted -eq $false) {
                    Start-Sleep -Milliseconds 200
                }
                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tOpen-Thread`t`$PowerShellInterface.Streams.ClearStreams() # after preloading command definitions for '$($ObjectString)'"
                $null = $PowerShellInterface.Streams.ClearStreams()

                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tOpen-Thread`t`$PowerShellInterface.EndInvoke(`$Handle) # after preloading command definitions for '$($ObjectString)'"
                $null = $PowerShellInterface.EndInvoke($Handle)

                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tOpen-Thread`t`$PowershellInterface.Commands.Clear() # after preloading command definitions for '$ObjectString'"
                $null = $PowershellInterface.Commands.Clear()
                #>

                $ScriptDefinition = [System.Text.StringBuilder]::new()
                $CommandStringForScriptDefinition = [System.Text.StringBuilder]::new($Command)

                # Build the param block of the script
                $null = $ScriptDefinition.AppendLine('param (')
                If ( -not [string]::IsNullOrEmpty($InputParameter)) {
                    $null = $ScriptDefinition.Append("    `$$InputParameter")
                    $null = $CommandStringForScriptDefinition.Append(" -$InputParameter `$InputParameter")
                }

                ForEach ($ThisKey in $AddParam.Keys) {
                    $null = $ScriptDefinition.Append(",`r`n    `$", $ThisKey)
                    $null = $CommandStringForScriptDefinition.Append(" -$ThisKey `$$ThisKey")
                }

                ForEach ($ThisSwitch in $AddSwitch) {
                    $null = $ScriptDefinition.Append(",`r`n    [switch]`$", $ThisSwitch)
                    $null = $CommandStringForScriptDefinition.Append(" -$ThisSwitch")
                }
                $null = $ScriptDefinition.AppendLine()
                $null = $ScriptDefinition.AppendLine(')')
                $null = $ScriptDefinition.AppendLine()
                [string[]]$CommandDefinitions = Convert-FromPsCommandInfoToString -CommandInfo $CommandInfo
                $null = $ScriptDefinition.AppendJoin("`r`n", $CommandDefinitions)
                $null = $ScriptDefinition.AppendLine()
                $null = $ScriptDefinition.AppendJoin('', $CommandStringForScriptDefinition)
                $ScriptString = $ScriptDefinition.ToString()
                $null = Add-PsCommand -Command $ScriptString -PowershellInterface $PowershellInterface -Force
            } else {
                $null = Add-PsCommand -Command $Command -PowershellInterface $PowershellInterface -Force
            }

            If ([string]::IsNullOrEmpty($InputParameter)) {
                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tOpen-Thread`t`$PowershellInterface.AddArgument('$ObjectString') # for '$Command' on '$ObjectString'"
                $null = $PowershellInterface.AddArgument($Object)
                <#NormallyCommentThisForPerformanceOptimization#>$InputParameterStringForDebug = "'$ObjectString'"
            } Else {
                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tOpen-Thread`t`$PowershellInterface.AddParameter('$InputParameter', '$ObjectString') # for '$Command' on '$ObjectString'"
                $null = $PowershellInterface.AddParameter($InputParameter, $Object)
                <#NormallyCommentThisForPerformanceOptimization#>$InputParameterStringForDebug = "-$InputParameter '$ObjectString'"
            }

            $AdditionalParameters = @()
            $AdditionalParameters = ForEach ($Key in $AddParam.Keys) {
                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tOpen-Thread`t`$PowershellInterface.AddParameter('$Key', '$($AddParam.$key)') # for '$Command' on '$ObjectString'"
                $null = $PowershellInterface.AddParameter($Key, $AddParam.$key)
                <#NormallyCommentThisForPerformanceOptimization#>"-$Key '$($AddParam.$key)'"
            }
            $AdditionalParametersString = $AdditionalParameters -join ' '

            $Switches = @()
            $Switches = ForEach ($Switch in $AddSwitch) {
                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tOpen-Thread`t`$PowershellInterface.AddParameter('$Switch') # for '$Command' on '$ObjectString'"
                $null = $PowershellInterface.AddParameter($Switch)
                <#NormallyCommentThisForPerformanceOptimization#>"-$Switch"
            }
            $SwitchParameterString = $Switches -join ' '

            $StatusString = "Invoking thread $CurrentObjectIndex`: $Command $InputParameterStringForDebug $AdditionalParametersString $SwitchParameterString"
            $Progress = @{
                Activity        = $StatusString
                PercentComplete = $CurrentObjectIndex / $ThreadCount * 100
                Status          = "$($ThreadCount - $CurrentObjectIndex) remaining"
            }
            Write-Progress @Progress

            Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tOpen-Thread`t`$Handle = `$PowershellInterface.BeginInvoke() # for '$Command' on '$ObjectString'"
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

        Write-Progress -Activity 'Completed' -Completed

    }
}
