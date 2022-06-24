
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
                    $ThisPowershell | Add-PsCommand -Command $CommandInfo.CommandInfo.Definition -CommandInfo $CommandInfo
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
        Name of a property (whose value is a string) that exists on each $InputObject and can be used to represent the object in text form
        If left null, the object's ToString() method will be used instead.
        #>
        [string]$ObjectStringProperty,

        <#
        Powershell output streams to pass through from the threads
        'All' is ignored if it is not the only value in the array
        #>
        [ValidateSet('All', 'None', 'Debug', 'Verbose', 'Information', 'Warning', 'Error')]
        [string[]]$OutputStream = 'None',

        # PowerShell Command or Script to run against each InputObject
        [Parameter(Mandatory = $true)]
        $Command,

        # Output from Get-PsCommandInfo
        [pscustomobject]$CommandInfo,

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

    }
    process {

        ForEach ($Object in $InputObject) {

            $CurrentObjectIndex++

            if ($ObjectStringProperty -ne '') {
                $ObjectString = $Object."$ObjectStringProperty"
            } else {
                $ObjectString = $Object.ToString()
            }

            $PowershellInterface = [powershell]::Create()
            $PowershellInterface.RunspacePool = $RunspacePool

            $null = $PowershellInterface.Commands.Clear()
            $null = $PowershellInterface | Add-PsCommand -Command $Command -CommandInfo $CommandInfo

            If (!([string]::IsNullOrEmpty($InputParameter))) {
                $null = $PowershellInterface.AddParameter($InputParameter, $Object)
                <#NormallyCommentThisForPerformanceOptimization#>$InputParameterString = "-$InputParameter '$ObjectString'"
            } Else {
                $null = $PowershellInterface.AddArgument($Object)
                <#NormallyCommentThisForPerformanceOptimization#>$InputParameterString = "'$ObjectString'"
            }

            $AdditionalParameters = @()
            $AdditionalParameters = ForEach ($Key in $AddParam.Keys) {
                $null = $PowershellInterface.AddParameter($Key, $AddParam.$key)
                <#NormallyCommentThisForPerformanceOptimization#>"-$Key '$($AddParam.$key)'"
            }
            $AdditionalParametersString = $AdditionalParameters -join ' '

            $Switches = @()
            $Switches = ForEach ($Switch in $AddSwitch) {
                $null = $PowershellInterface.AddParameter($Switch)
                <#NormallyCommentThisForPerformanceOptimization#>"-$Switch"
            }
            $SwitchParameterString = $Switches -join ' '

            $StatusString = "Invoking thread $CurrentObjectIndex`: $Command $InputParameterString $AdditionalParametersString $SwitchParameterString"
            <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tOpen-Thread`t$StatusString"
            $Progress = @{
                Activity        = $StatusString
                PercentComplete = $CurrentObjectIndex / $ThreadCount * 100
                Status          = "$($ThreadCount - $CurrentObjectIndex) remaining"
            }
            Write-Progress @Progress

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
function Split-Thread {

    <#
    .Synopsis
        Splits a command for a collection of input objects into multiple threads for asynchronous processing

    .Description
        The specified command will be run for each input object in a separate powershell instance with its own runspace
        These runspaces are part of the same runspace pool inside the same powershell.exe process

    .EXAMPLE
        The following demonstrates sending a Cmdlet name to the -Command parameter
            $InputObject | Split-Thread -Command 'Write-Output'

    .EXAMPLE
        The following demonstrates sending a scriptblock to the -Command parameter
            $InputObject | Split-Thread -Command [scriptblock]::create("Write-Output `$args[0]")

    .EXAMPLE
        The following demonstrates sending a script file path to the -Command parameter
            $InputObject | Split-Thread -Command "C:\Test-Command.ps1"

    .EXAMPLE
        The following demonstrates sending a function to the -Command parameter
            $InputObject | Split-Thread -Command 'Test-Function'

    .EXAMPLE
        The following demonstrates the -AddParam parameter

        $InputObject | Split-Thread -Command "Get-Service" -InputParameter ComputerName -AddParam @{"Name" = "BITS"}

    .EXAMPLE
        The following demonstrates the -AddSwitch parameter

        $InputObject | Split-Thread -Command "Get-Service" -AddSwitch @('RequiredServices','DependentServices')

	.EXAMPLE
		The following demonstrates the use of a threadsafe hashtable to store results
		The hastable can be accessed and updated from inside each runspace

		$ThreadsafeHashtable = [hashtable]::Synchronized(@{})
		$InputObject | Split-Thread -Command "Fake-Function" -InputParameter ComputerName -AddParam @{"ResultHashTableParameter" = $ThreadsafeHashtable}
    #>

    param (

        # PowerShell Command or Script to run against each InputObject
        [Parameter(Mandatory = $true)]
        $Command,

        # Objects to pass to the Command as an argument or parameter
        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        $InputObject,

        # Named parameter of the Command to pass InputObject to
        # If this is not specified, InputObject will be passed to the Command as an argument
        $InputParameter = $null,

        # Maximum number of concurrent threads to allow
        [int]$Threads = 20,

        # Milliseconds to wait between cycles of the loop that checks threads for completion
        [int]$SleepTimer = 200,

        # Seconds to wait without receiving any new results before giving up and stopping all remaining threads
        [int]$Timeout = 120,

        <#
        Parameters to add to the Command
        Each parameter is a name-value pair in the hashtable:
            @{"ParameterName" = "Value"}
            @{"ParameterName" = "Value" ; "ParameterTwo" = "Value2"}
        #>
        [HashTable]$AddParam = @{},

        # Switches to add to the Command
        [string[]]$AddSwitch = @(),

        # Names of modules to import in each runspace
        [String[]]$AddModule,

        <#
        Name of a property (whose value is a string) that exists on each $InputObject and can be used to represent the object in text form
        If left null, the object's ToString() method will be used instead.
        #>
        [string]$ObjectStringProperty,

        # Suppress Powershell output streams from the threads
        [ValidateSet('All', 'None', 'Debug', 'Verbose', 'Information', 'Warning', 'Error')]
        [string[]]$OutputStream = 'None'

    )

    begin {

        $InitialSessionState = [system.management.automation.runspaces.initialsessionstate]::CreateDefault()

        <#
        Some modules (for example a module imported directly from a .psm1 file) will have a Definition property that contains all the module's code.
            We will run that Definition code inside the runspace.
            This is done most reliably by dumping the definition to a .psm1 file in a temp directory, then loading it into the InitialSessionState using the ImportPSModulesFromPath($TempDir) method
            TODO: skip temp dir in cases where .psm1 path already known?
        Other modules (for example the Active Directory module) have a null Definition property.
            In that case we will just try to import the module using Import-Module.
        #>

        $TempDir = "$Env:TEMP\PsRunspace"
        $ModulesDir = "$TempDir\$((Get-Date -format s) -replace ':')"
        $null = New-Item -ItemType Directory -Path $ModulesDir -ErrorAction SilentlyContinue

        $CommandInfo = Get-PsCommandInfo -Command $Command

        ForEach ($Module in $AddModule) {

            $ModuleObj = Get-Module $Module -ErrorAction SilentlyContinue

            if ($ModuleObj.Definition) {
                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tSplit-Thread`tDefinition found for module '$Module'. Will import definition in each runspace."
                #CommentedForPerformanceOptimization#Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tSplit-Thread`tDefinition found for module '$Module'. Will import definition in each runspace."

                $ModuleDir = "$ModulesDir\$($ModuleObj.Name)"
                $null = New-Item -ItemType Directory -Path $ModuleDir -ErrorAction SilentlyContinue
                $ModuleObj.Definition | Out-File -LiteralPath "$ModuleDir\$($ModuleObj.Name).psm1" -Force

            } else {

                #CommentedForPerformanceOptimization#Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tSplit-Thread`tNo definition found for module '$Module'. Will load module by name in each runspace."

                $InitialSessionState.ImportPSModule($Module)

            }

        }

        if ($CommandInfo.SourceModuleDefinition -and $AddModule -notcontains $CommandInfo.CommandInfo.Source) {
            #CommentedForPerformanceOptimization#Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tSplit-Thread`tDefinition found for source module '$($CommandInfo.CommandInfo.Source)'. Will import definition in each runspace."
            $ModuleDir = "$ModulesDir\$($CommandInfo.CommandInfo.Source)"
            $null = New-Item -ItemType Directory -Path $ModuleDir -ErrorAction SilentlyContinue
            $CommandInfo.SourceModuleDefinition | Out-File -LiteralPath "$ModuleDir\$($CommandInfo.CommandInfo.Source).psm1" -Force
        }

        if ($CommandInfo.SourceModuleName -and $AddModule -notcontains $CommandInfo.SourceModuleName) {
            #CommentedForPerformanceOptimization#Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tSplit-Thread`tImporting source module by name '$($CommandInfo.CommandInfo.Source)'."
            $InitialSessionState.ImportPSModule($CommandInfo.SourceModuleName)
        }

        $InitialSessionState.ImportPSModulesFromPath($ModulesDir)

        if ($OutputStream -ne 'None') {

            if ($OutputStream -eq 'All') {
                $OutputStream = @('Debug', 'Verbose', 'Information', 'Warning', 'Error')
            }

            ForEach ($ThisStream in $OutputStream) {
                if ($ThisStream -eq 'Error') {
                    $variableEntry = [System.Management.Automation.Runspaces.SessionStateVariableEntry]::new('ErrorActionPreference', 'Continue', '')
                } else {
                    $variableEntry = [System.Management.Automation.Runspaces.SessionStateVariableEntry]::new("$ThisStream`Preference", 'Continue', '')
                }
                $InitialSessionState.Variables.Add($variableEntry)
            }

        }

        $RunspacePool = [runspacefactory]::CreateRunspacePool(1, $Threads, $InitialSessionState, $Host)
        $RunspacePool.Open()

        $Global:TimedOut = $false

        $AllInputObjects = [System.Collections.Generic.List[psobject]]::new()

    }

    process {

        ForEach ($ThisObject in $InputObject) {
            $null = $AllInputObjects.Add($ThisObject)
        }

    }
    end {

        $ThreadParameters = @{
            Command              = $Command
            InputParameter       = $InputParameter
            InputObject          = $AllInputObjects
            AddParam             = $AddParam
            AddSwitch            = $AddSwitch
            OutputStream         = $OutputStream
            ObjectStringProperty = $ObjectStringProperty
            CommandInfo          = $CommandInfo
            RunspacePool         = $RunspacePool
        }
        $AllThreads = Open-Thread @ThreadParameters

        Wait-Thread -Thread $AllThreads -Threads $Threads -SleepTimer $SleepTimer -Timeout $Timeout -Dispose

        if ($Global:TimedOut -eq $false) {

            #CommentedForPerformanceOptimization#Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tSplit-Thread`t[System.Management.Automation.Runspaces.RunspacePool]::Close()"
            $null = $RunspacePool.Close()
            #CommentedForPerformanceOptimization#Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tSplit-Thread`t[System.Management.Automation.Runspaces.RunspacePool]::Close() completed"

            #CommentedForPerformanceOptimization#Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tSplit-Thread`t[System.Management.Automation.Runspaces.RunspacePool]::Dispose()"
            $null = $RunspacePool.Dispose()
            #CommentedForPerformanceOptimization#Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tSplit-Thread`t[System.Management.Automation.Runspaces.RunspacePool]::Dispose() completed"

        }

        Write-Progress -Activity 'Completed' -Completed

    }

}
function Wait-Thread {

    <#
    .Synopsis
        Waits for a thread to be completed so the results can be returned, or for a timeout to be reached

    .Description
        Used by Split-Thread

    .INPUTS
        [PSCustomObject]$Thread

    .OUTPUTS
        Outputs the specified output streams from the threads
    #>

    param (

        # Threads to wait for
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [PSCustomObject[]]$Thread,

        # Maximum number of concurrent threads that are allowed (used only for progress display)
        [int]$Threads = 20,

        # Milliseconds to wait between cycles of the loop that checks threads for completion
        [int]$SleepTimer = 200,

        # Seconds to wait without receiving any new results before giving up and stopping all remaining threads
        [int]$Timeout = 120,

        # Dispose of the thread when it is finished
        [switch]$Dispose

    )

    begin {

        $StopWatch = [System.Diagnostics.Stopwatch]::new()
        $StopWatch.Start()

        $AllThreads = [System.Collections.Generic.List[PSCustomObject]]::new()

        $RunspacePool = ($Thread | Select-Object -First 1).PowershellInterface.RunspacePool

        $CommandString = ($Thread | Select-Object -First 1).Command

    }

    process {

        ForEach ($ThisThread in $Thread) {

            # If the threads do not have handles, there is nothing to wait for, so output the thread as-is.
            # Otherwise wait for the handle to indicate completion (or a timeout to be reached)
            if ($ThisThread.Handle -eq $false) {
                $null = $ThisThread.PowerShellInterface.Streams.ClearStreams()
                $ThisThread
            } else {
                $null = $AllThreads.Add($ThisThread)
            }

        }

    }

    end {

        # If the threads have handles, we can check to see if they are complete.
        While (@($AllThreads | Where-Object -FilterScript { $null -ne $_.Handle }).Count -gt 0) {

            if ($RunspacePool) { $AvailableRunspaces = $RunspacePool.GetAvailableRunspaces() }

            $CleanedUpThreads = [System.Collections.Generic.List[PSCustomObject]]::new()
            $CompletedThreads = [System.Collections.Generic.List[PSCustomObject]]::new()
            $IncompleteThreads = [System.Collections.Generic.List[PSCustomObject]]::new()
            ForEach ($ThisThread in $AllThreads) {
                if ($null -eq $ThisThread.Handle) {
                    $null = $CleanedUpThreads.Add($ThisThread)
                }
                if ($ThisThread.Handle.IsCompleted -eq $true) {
                    $null = $CompletedThreads.Add($ThisThread)
                }
                if ($ThisThread.Handle.IsCompleted -eq $false) {
                    $null = $IncompleteThreads.Add($ThisThread)
                }
            }

            $ActiveThreadCountString = "$($Threads - $AvailableRunspaces) of $Threads are active"

            #CommentedForPerformanceOptimization#Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`t$ActiveThreadCountString"
            #CommentedForPerformanceOptimization#Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`t$($CompletedThreads.Count) completed threads"
            #CommentedForPerformanceOptimization#Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`t$($CleanedUpThreads.Count) cleaned up threads"
            #CommentedForPerformanceOptimization#Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`t$($IncompleteThreads.Count) incomplete threads"

            $RemainingString = "$($IncompleteThreads.ObjectString)"
            If ($RemainingString.Length -gt 60) {
                $RemainingString = $RemainingString.Substring(0, 60) + "..."
            }

            $Progress = @{
                Activity        = "Waiting on threads - $ActiveThreadCountString`: $CommandString"
                PercentComplete = ($($CleanedUpThreads).count) / @($Thread).Count * 100
                Status          = "$(@($IncompleteThreads).Count) remaining - $RemainingString"
            }
            Write-Progress @Progress

            ForEach ($CompletedThread in $CompletedThreads) {

                #Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`t$($CompletedThread.PowerShellInterface.Streams.Progress.Count) Progress messages"
                #Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`t$($CompletedThread.PowerShellInterface.Streams.Information.Count) Information messages"
                #Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`t$($CompletedThread.PowerShellInterface.Streams.Verbose.Count) Verbose messages"
                #Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`t$($CompletedThread.PowerShellInterface.Streams.Debug.Count) Debug messages"
                #Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`t$($CompletedThread.PowerShellInterface.Streams.Warning.Count) Warning messages"

                # Because $Host was used to create the RunspacePool, any output to $Host (which includes Write-Host and Write-Information and Write-Progress) has already been displayed
                #$CompletedThread.PowerShellInterface.Streams.Progress | ForEach-Object {Write-Progress $_}
                #$CompletedThread.PowerShellInterface.Streams.Information | ForEach-Object {Write-Information $_}
                #$CompletedThread.PowerShellInterface.Streams.Verbose | ForEach-Object {Write-Verbose $_}
                #$CompletedThread.PowerShellInterface.Streams.Debug | ForEach-Object {Write-Debug $_}
                #$CompletedThread.PowerShellInterface.Streams.Warning | ForEach-Object {Write-Warning $_}

                $null = $CompletedThread.PowerShellInterface.Streams.ClearStreams()

                if ($Dispose -eq $true) {
                    $ThreadOutput = $CompletedThread.PowerShellInterface.EndInvoke($CompletedThread.Handle)
                    #NormallyCommentThisForPerformanceOptimization#>if (($ThreadOutput | Measure-Object).Count -gt 0) {
                    #NormallyCommentThisForPerformanceOptimization#>Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`tOutput (count of $($ThreadOutput.Count)) received from thread $($CompletedThread.Index): $($CompletedThread.ObjectString)"
                    #NormallyCommentThisForPerformanceOptimization#>}
                    #NormallyCommentThisForPerformanceOptimization#>else {
                    #NormallyCommentThisForPerformanceOptimization#>Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`tNull result for thread $($CompletedThread.Index) ($($CompletedThread.ObjectString))"
                    #NormallyCommentThisForPerformanceOptimization#>}
                    $ThreadOutput
                    $null = $CompletedThread.PowerShellInterface.Dispose()
                    $CompletedThread.PowerShellInterface = $null
                    $CompletedThread.Handle = $null
                } else {
                    #CommentedForPerformanceOptimization#Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`tThread $($CompletedThread.Index) ($($CompletedThread.ObjectString)) is finished opening."
                    $null = $CompletedThread.PowerShellInterface.EndInvoke($CompletedThread.Handle)
                    $CompletedThread.Handle = $null
                    $CompletedThread
                }

                $StopWatch.Reset()
                $StopWatch.Start()

            }

            If ($StopWatch.ElapsedMilliseconds / 1000 -gt $Timeout) {

                Write-Warning "$(Get-Date -Format s)`t$(hostname)`tWait-Thread`tReached Timeout of $Timeout seconds. Skipping $($IncompleteThreads.Count) remaining threads: $RemainingString"

                $Global:TimedOut = $true

                $IncompleteThreads | ForEach-Object {
                    [PSCustomObject]@{
                        Handle              = $null
                        PowerShellInterface = $_.PowershellInterface
                        Object              = $_.Object
                        ObjectString        = $_.ObjectString
                        Index               = $_.CurrentObjectIndex
                        Command             = $_.Command
                    }
                }
            }

            #CommentedForPerformanceOptimization#Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`tSleeping $SleepTimer milliseconds"
            Start-Sleep -Milliseconds $SleepTimer

        }

        $StopWatch.Stop()

        #CommentedForPerformanceOptimization#Write-Verbose "$(Get-Date -Format s)`t$(hostname)`tWait-Thread`tFinished waiting for threads"
        Write-Progress -Activity 'Completed' -Completed

    }

}

$ScriptFiles = Get-ChildItem -Path "$PSScriptRoot\*.ps1" | Where-Object -FilterScript {
    ($_.PSParentPath | Split-Path -Leaf) -eq 'TestCode'
}

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






