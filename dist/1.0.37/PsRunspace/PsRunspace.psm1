
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

                [System.Management.Automation.CommandTypes]::Alias {
                    # Resolve the alias to its command and start from the beginning with that command.
                    $CommandInfo = Get-PsCommandInfo -Command $CommandInfo.CommandInfo.Definition
                    $null = Add-PsCommand -Command $CommandInfo.CommandInfo.Definition -CommandInfo $CommandInfo -PowershellInterface $ThisPowerShell
                }
                [System.Management.Automation.CommandTypes]::Function {
                    # Add the definitions of the function
                    # BUG: Look at the definition of Get-Member for example, it is not in a ScriptModule so its definition is not PowerShell code
                    [string]$ThisFunction = "function $($CommandInfo.CommandInfo.Name) {`r`n$($CommandInfo.CommandInfo.Definition)`r`n}"
                    <#NormallyCommentThisForPerformanceOptimization#>##Write-Debug "Add-PsCommand adding Script (the Definition of a Function)"
                    Write-Debug "`$PowershellInterface.AddScript('function $($CommandInfo.CommandInfo.Name) {...}')"
                    $null = $ThisPowershell.AddScript($ThisFunction)
                }
                'ScriptBlock' {
                    <#NormallyCommentThisForPerformanceOptimization#>##Write-Debug "Add-PsCommand adding Script (a ScriptBlock)"
                    Write-Debug "`$PowershellInterface.AddScript('$Command')"
                    $null = $ThisPowershell.AddScript($Command)
                }
                [System.Management.Automation.CommandTypes]::ExternalScript {
                    <#NormallyCommentThisForPerformanceOptimization#>##Write-Debug "Add-PsCommand adding Script (the ScriptBlock of an ExternalScript)"
                    Write-Debug "`$PowershellInterface.AddScript('$($CommandInfo.ScriptBlock)')"
                    $null = $ThisPowershell.AddScript($CommandInfo.ScriptBlock)
                }
                default {
                    Write-Debug "Add-PsCommand adding command '$Command' of type '$($CommandInfo.CommandType)'"
                    # If the type is All, Application, Cmdlet, Configuration, Filter, or Script then run the command as-is
                    Write-Debug "`$PowershellInterface.AddStatement().AddCommand('$Command')"
                    $null = $ThisPowershell.AddStatement().AddCommand($Command)
                }

            }
        }
    }
}
function Add-PsModule {
    <#
    .Synopsis
        Import a Module in a [System.Management.Automation.Runspaces.InitialSessionState] instance
    .Description
        Used by Add-PsCommand
        Uses ImportPSModule() or ImportPSModulesFromPath() depending on the module
    .EXAMPLE
        $InitialSessionState = [system.management.automation.runspaces.initialsessionstate]::CreateDefault()
        Add-PsModule -InitialSessionState $InitialSessionState -ModuleInfo $ModuleInfo
    #>

    param(

        # Powershell interface to add the Command to
        [Parameter(Mandatory)]
        [System.Management.Automation.Runspaces.InitialSessionState]$InitialSessionState,

        <#
        ModuleInfo object for the module to add to the Powershell interface
        #>
        [Parameter(
            Mandatory,
            Position = 0
        )]
        [System.Management.Automation.PSModuleInfo[]]$ModuleInfo

    )

    process {

        ForEach ($ThisModule in $ModuleInfo) {

            switch ($ThisModule.ModuleType) {
                'Binary' {
                    Write-Debug "`$InitialSessionState.ImportPSModule('$($ThisModule.Name)')"
                    $InitialSessionState.ImportPSModule($ThisModule.Name)
                }
                'Script' {
                    $ModulePath = Split-Path -Path $ThisModule.Path -Parent
                    Write-Debug "`$InitialSessionState.ImportPSModulesFromPath('$ModulePath')"
                    $InitialSessionState.ImportPSModulesFromPath($ModulePath)
                }
                'Manifest' {
                    $ModulePath = Split-Path -Path $ThisModule.Path -Parent
                    Write-Debug "`$InitialSessionState.ImportPSModulesFromPath('$ModulePath')"
                    $InitialSessionState.ImportPSModulesFromPath($ModulePath)
                }
                default {
                    # Scriptblocks or Functions not from modules will have no module to import so ModuleInfo will be null
                }
            }

        }
    }

}
function Expand-PsCommandInfo {

    <#
    .SYNOPSIS
        Return the original PsCommandInfo object as well as CommandInfo objects for any nested commands
    #>

    param (
        # CommandInfo object for the command whose nested command names to return
        [PSCustomObject]$PsCommandInfo,

        # Cache of already identified CommmandInfo objects
        [hashtable]$Cache = [hashtable]::Synchronized(@{})
    )

    # Add the first object to the cache
    $Cache[$PsCommandInfo.CommandInfo.Name] = $PsCommandInfo

    # Tokenize the function definition
    $PsTokens = $null
    $TokenizerErrors = $null
    $AbstractSyntaxTree = [System.Management.Automation.Language.Parser]::ParseInput(
        $PsCommandInfo.CommandInfo.Definition,
        [ref]$PsTokens,
        [ref]$TokenizerErrors
    )

    # Get all nested tokens
    $AllPsTokens = Expand-PsToken -InputObject $PsTokens

    # Find any other functions we also need to add
    $CommandTokens = $AllPsTokens |
    Where-Object -FilterScript {
        $_.Kind -eq 'Generic' -and
        $_.TokenFlags.HasFlag([System.Management.Automation.Language.TokenFlags]::CommandName)
    }

    # Add the definitions of those functions if available
    # TODO: Add modules if available? Not needed at this time but maybe later
    ForEach ($ThisCommandToken in $CommandTokens) {
        if (
            -not $Cache[$ThisCommandToken.Value] -and
            $ThisCommandToken.Value -notmatch '[\.\\]' # This excludes any file paths since they are not PowerShell commands with tokenizable definitions (they contain \ or .)
        ) {
            $TokenCommandInfo = Get-PsCommandInfo -Command $ThisCommandToken.Value
            $Cache[$ThisCommandToken.Value] = $TokenCommandInfo

            # Suppress the output of the Expand-PsCommandInfo function because we will instead be using the updated cache contents
            # This way the results are already deduplicated for us by the hashtable
            $null = Expand-PsCommandInfo -PsCommandInfo $TokenCommandInfo -Cache $Cache
        }
    }

    # Output the objects in the cache
    ForEach ($ThisKey in $Cache.Keys) {
        $Cache[$ThisKey]
    }

}
function Expand-PsToken {
    <#
    .SYNOPSIS
        Recursively get nested tokens
    .DESCRIPTION
        Recursively emits all tokens embedded in a token of type "StringExpandable"
        The original token is also emitted.
    .EXAMPLE
        $Tokens = $null
        $TokenizerErrors = $null
        $AbstractSyntaxTree = [System.Management.Automation.Language.Parser]::ParseInput(
          [string]$Code,
          [ref]$Tokens,
          [ref]$TokenizerErrors
      )
      $Tokens |
      Expand-PsToken

      Return all tokens nested inside the provided $Code
    #>

    param (
        # Management.Automation.Language.StringExpandableToken or
        # Management.Automation.Language.Token
        [Parameter(
            Mandatory,
            Position = 0
        )]
        [psobject]$InputObject
    )

    process {
        if ($InputObject.GetType().FullName -eq 'Management.Automation.Language.StringExpandableToken]') {
            ForEach ($ThisToken in $InputObject.NestedTokens) {
                if ($ThisToken) {
                    Expand-PsToken -InputObject $ThisToken
                }
            }
        }
        $InputObject
    }

}
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
        Write-Debug "Open-Thread received $(($CommandInfo | Measure-Object).Count) filtered PsCommandInfos from Split-Thread"

    }
    process {

        ForEach ($Object in $InputObject) {

            $CurrentObjectIndex++

            if ($ObjectStringProperty -ne '') {
                [string]$ObjectString = $Object."$ObjectStringProperty"
            } else {
                [string]$ObjectString = $Object.ToString()
            }

            Write-Debug '$PowershellInterface = [powershell]::Create()'
            $PowershellInterface = [powershell]::Create()

            Write-Debug '$PowershellInterface.RunspacePool = $RunspacePool'
            $PowershellInterface.RunspacePool = $RunspacePool

            Write-Debug '$PowershellInterface.Commands.Clear()'
            $null = $PowershellInterface.Commands.Clear()

            ForEach ($ThisCommandInfo in $CommandInfo) {
                $null = Add-PsCommand -Command $ThisCommandInfo.CommandInfo.Name -CommandInfo $ThisCommandInfo -PowershellInterface $PowershellInterface
            }

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
            Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tOpen-Thread`t$StatusString"
            Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tOpen-Thread`t$StatusString"
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
        Split a command for a collection of input objects into multiple threads for asynchronous processing
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
        [string]$ObjectStringProperty

    )

    begin {
        Write-Debug "Split-Thread entered begin block for $Command"

        Write-Debug '$InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()'
        $InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()

        # Import the source module containing the specified Command in each thread

        $OriginalCommandInfo = Get-PsCommandInfo -Command $Command
        Write-Debug "Split-Thread found 1 original PsCommandInfo"
        $CommandInfo = Expand-PsCommandInfo -PsCommandInfo $OriginalCommandInfo
        Write-Debug "Split-Thread found $(($CommandInfo | Measure-Object).Count) nested PsCommandInfos"

        # Prepare our collection of PowerShell modules to import in each thread
        # This will include any modules specified by name with the -AddModule parameter
        # This will also include any modules identified by tokenizing the -Command parameter or its definition, and recursing through all nested command tokens
        $ModulesToAdd = [System.Collections.Generic.List[System.Management.Automation.PSModuleInfo]]::new()
        ForEach ($Module in $AddModule) {
            $ModuleObj = Get-Module $Module -ErrorAction SilentlyContinue
            $null = $ModulesToAdd.Add($ModuleObj)
        }

        $ModulesToAdd = $CommandInfo.ModuleInfo |
        Sort-Object -Property Name -Unique

        $CommandInfo = $CommandInfo |
        Where-Object -FilterScript {
            $ModulesToAdd.Name -notcontains $_.ModuleInfo.Name ###-and
            ###-not [string]::IsNullOrEmpty($_.CommandInfo.Name)
        }
        Write-Debug "Split-Thread found $(($CommandInfo | Measure-Object).Count) filtered PsCommandInfos"

        if (($CommandInfo | Measure-Object).Count -eq 0) {
            $CommandInfo = $OriginalCommandInfo
        }

        $null = Add-PsModule -InitialSessionState $InitialSessionState -ModuleInfo $ModulesToAdd

        # Set the preference variables for PowerShell output streams in each thread to match the current preferences
        $OutputStream = @('Debug', 'Verbose', 'Information', 'Warning', 'Error')
        ForEach ($ThisStream in $OutputStream) {
            if ($ThisStream -eq 'Error') {
                $VariableName = 'ErrorActionPreference'
            } else {
                $VariableName = "$($ThisStream)Preference"
            }
            $VariableValue = (Get-Variable -Name $VariableName).Value
            $VariableEntry = [System.Management.Automation.Runspaces.SessionStateVariableEntry]::new($VariableName, $VariableValue, '')
            $InitialSessionState.Variables.Add($VariableEntry)
        }

        Write-Debug "`$RunspacePool = [runspacefactory]::CreateRunspacePool(1, $Threads, `$InitialSessionState, `$Host)"
        $RunspacePool = [runspacefactory]::CreateRunspacePool(1, $Threads, $InitialSessionState, $Host)
        #####don'trememberwhythisishere#####$VerbosePreference = 'SilentlyContinue'
        Write-Debug '$RunspacePool.Open()'
        $RunspacePool.Open()

        $Global:TimedOut = $false

        $AllInputObjects = [System.Collections.Generic.List[psobject]]::new()

    }

    process {
        Write-Debug "Split-Thread entered process block for $Command"

        # Add all the input objects from the pipeline to a single collection; allows progress bars later
        ForEach ($ThisObject in $InputObject) {
            $null = $AllInputObjects.Add($ThisObject)
        }

    }
    end {
        Write-Debug "Split-Thread entered end block for $Command"
        Write-Debug "Split-Thread sending $(($CommandInfo | Measure-Object).Count) filtered PsCommandInfos to Open-Thread"
        $ThreadParameters = @{
            Command              = $Command
            InputParameter       = $InputParameter
            InputObject          = $AllInputObjects
            AddParam             = $AddParam
            AddSwitch            = $AddSwitch
            ObjectStringProperty = $ObjectStringProperty
            CommandInfo          = $CommandInfo
            RunspacePool         = $RunspacePool
        }
        $AllThreads = Open-Thread @ThreadParameters
        Write-Debug "Split-Thread received $(($AllThreads | Measure-Object).Count) threads from Open-Thread for $Command"
        Wait-Thread -Thread $AllThreads -Threads $Threads -SleepTimer $SleepTimer -Timeout $Timeout -Dispose
        $VerbosePreference = 'Continue'

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

        $FirstThread = $Thread | Select-Object -First 1

        $RunspacePool = $FirstThread.PowershellInterface.RunspacePool

        $CommandString = $FirstThread.Command

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

            Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`t$ActiveThreadCountString"
            Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`t$($CompletedThreads.Count) completed threads"
            Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`t$($CleanedUpThreads.Count) cleaned up threads"
            Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`t$($IncompleteThreads.Count) incomplete threads"

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

                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`t$($CompletedThread.PowerShellInterface.Streams.Progress.Count) Progress messages"
                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`t$($CompletedThread.PowerShellInterface.Streams.Information.Count) Information messages"
                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`t$($CompletedThread.PowerShellInterface.Streams.Verbose.Count) Verbose messages"
                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`t$($CompletedThread.PowerShellInterface.Streams.Debug.Count) Debug messages"
                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`t$($CompletedThread.PowerShellInterface.Streams.Warning.Count) Warning messages"

                # Because $Host was used to create the RunspacePool, any output to $Host (which includes Write-Host and Write-Information and Write-Progress) has already been displayed
                #$CompletedThread.PowerShellInterface.Streams.Progress | ForEach-Object {Write-Progress "$_"}
                #$CompletedThread.PowerShellInterface.Streams.Information | ForEach-Object { Write-Information "$_" }
                #$CompletedThread.PowerShellInterface.Streams.Verbose | ForEach-Object { Write-Verbose "$_" }
                #$CompletedThread.PowerShellInterface.Streams.Debug | ForEach-Object { Write-Debug "$_" }
                #$CompletedThread.PowerShellInterface.Streams.Warning | ForEach-Object { Write-Warning "$_" }

                $null = $CompletedThread.PowerShellInterface.Streams.ClearStreams()

                if ($Dispose -eq $true) {
                    $ThreadOutput = $CompletedThread.PowerShellInterface.EndInvoke($CompletedThread.Handle)
                    <#NormallyCommentThisForPerformanceOptimization#>#if (($ThreadOutput | Measure-Object).Count -gt 0) {
                    Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`tOutput (count of $($ThreadOutput.Count)) received from thread $($CompletedThread.Index): $($CompletedThread.ObjectString)"
                    <#NormallyCommentThisForPerformanceOptimization#>#}
                    <#NormallyCommentThisForPerformanceOptimization#>#else {
                    Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`tNull result for thread $($CompletedThread.Index) ($($CompletedThread.ObjectString))"
                    <#NormallyCommentThisForPerformanceOptimization#>#}
                    $ThreadOutput
                    $null = $CompletedThread.PowerShellInterface.Dispose()
                    $CompletedThread.PowerShellInterface = $null
                    $CompletedThread.Handle = $null
                } else {
                    Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`tThread $($CompletedThread.Index) ($($CompletedThread.ObjectString)) is finished opening."
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

                $IncompleteThreads |
                ForEach-Object {
                    $_.Handle = $null
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

            Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`tSleeping $SleepTimer milliseconds"
            Start-Sleep -Milliseconds $SleepTimer

        }

        $StopWatch.Stop()

        #NormallyCommentThisForPerformanceOptimization#Write-Verbose "$(Get-Date -Format s)`t$(hostname)`tWait-Thread`tFinished waiting for threads"
        Write-Progress -Activity 'Completed' -Completed

    }

}

<#
# Dot source any functions
ForEach ($ThisScript in $ScriptFiles) {
    # Dot source the function
    . $($ThisScript.FullName)
}
#>
Export-ModuleMember -Function @('Add-PsCommand','Add-PsModule','Expand-PsCommandInfo','Expand-PsToken','Get-PsCommandInfo','Open-Thread','Split-Thread','Wait-Thread')





















