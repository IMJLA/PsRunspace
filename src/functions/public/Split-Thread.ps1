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
        [string]$ObjectStringProperty,

        # Will be sent to the Type parameter of Write-LogMsg in the PsLogMessage module
        [string]$DebugOutputStream = 'Silent',

        [string]$TodaysHostname = (HOSTNAME.EXE)

    )

    begin {

        $LogParams = @{
            Type         = $DebugOutputStream
            ThisHostname = $TodaysHostname
        }

        Write-LogMsg @LogParams -Text "  # Entered begin block for '$Command'"

        Write-LogMsg @LogParams -Text "  `$InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault() # for '$Command'"
        $InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()

        # Import the source module containing the specified Command in each thread

        $OriginalCommandInfo = Get-PsCommandInfo -Command $Command -DebugOutputStream $DebugOutputStream -TodaysHostname $TodaysHostname
        Write-LogMsg @LogParams -Text "  # Found 1 original PsCommandInfo for '$Command'"

        $CommandInfo = Expand-PsCommandInfo -PsCommandInfo $OriginalCommandInfo -DebugOutputStream $DebugOutputStream -TodaysHostname $TodaysHostname
        Write-LogMsg @LogParams -Text "  # Found $(($CommandInfo | Measure-Object).Count) nested PsCommandInfos for '$Command' ($($CommandInfo.CommandInfo.Name -join ','))"

        # Prepare our collection of PowerShell modules to import in each thread
        # This will include any modules specified by name with the -AddModule parameter
        $ModulesToAdd = [System.Collections.Generic.List[System.Management.Automation.PSModuleInfo]]::new()
        ForEach ($Module in $AddModule) {
            Write-LogMsg @LogParams -Text "  Get-Module -Name '$Module'"
            $ModuleObj = Get-Module -Name $Module -ErrorAction SilentlyContinue
            $null = $ModulesToAdd.Add($ModuleObj)
        }

        # This will also include any modules identified by tokenizing the -Command parameter or its definition, and recursing through all nested command tokens
        $OriginalCommandInfo.ModuleInfo |
        ForEach-Object {
            $null = $ModulesToAdd.Add($_)
        }
        $CommandInfo.ModuleInfo |
        ForEach-Object {
            $null = $ModulesToAdd.Add($_)
        }
        $ModulesToAdd = $ModulesToAdd |
        Sort-Object -Property Name -Unique

        $CommandsToAdd = [System.Collections.Generic.List[System.Management.Automation.PSCustomObject]]::new()
        $OriginalCommandInfo |
        Where-Object -FilterScript {
            $ModulesToAdd.Name -notcontains $_.ModuleInfo.Name -and
            $_.CommandType -ne 'Cmdlet'
        } |
        ForEach-Object {
            $null = $CommandsToAdd.Add($_)
        }
        $CommandInfo |
        Where-Object -FilterScript {
            $ModulesToAdd.Name -notcontains $_.ModuleInfo.Name -and
            $_.CommandType -ne 'Cmdlet'
        } |
        ForEach-Object {
            $null = $CommandsToAdd.Add($_)
        }
        Write-LogMsg @LogParams -Text "  # Found $(($CommandInfo | Measure-Object).Count) remaining PsCommandInfos to define for '$Command' (not in modules: $($CommandInfo.CommandInfo.Name -join ','))"

        if ($ModulesToAdd.Count -gt 0) {
            $null = Add-PsModule -InitialSessionState $InitialSessionState -ModuleInfo $ModulesToAdd -DebugOutputStream $DebugOutputStream -TodaysHostname $TodaysHostname
        }

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

        Write-LogMsg @LogParams -Text "  `$RunspacePool = [runspacefactory]::CreateRunspacePool(1, $Threads, `$InitialSessionState, `$Host) # for '$Command'"
        $RunspacePool = [runspacefactory]::CreateRunspacePool(1, $Threads, $InitialSessionState, $Host)
        Write-LogMsg @LogParams -Text "  `$RunspacePool.Open() # for '$Command'"
        $RunspacePool.Open()

        $Global:TimedOut = $false

        $AllInputObjects = [System.Collections.Generic.List[psobject]]::new()

    }

    process {
        if ($ObjectStringProperty) {
            $ObjectString = $InputObject.$ObjectStringProperty
        } else {
            $ObjectString = $InputObject.ToString()
        }
        Write-LogMsg @LogParams -Text "  # Entered process block for '$Command' on '$ObjectString'"

        # Add all the input objects from the pipeline to a single collection; allows progress bars later
        ForEach ($ThisObject in $InputObject) {
            $null = $AllInputObjects.Add($ThisObject)
        }

    }
    end {
        Write-LogMsg @LogParams -Text "  # Entered end block for '$Command'"
        Write-LogMsg @LogParams -Text "  # Sending $(($CommandInfo | Measure-Object).Count) PsCommandInfos to Open-Thread for '$Command'"
        $ThreadParameters = @{
            Command              = $Command
            InputParameter       = $InputParameter
            InputObject          = $AllInputObjects
            AddParam             = $AddParam
            AddSwitch            = $AddSwitch
            ObjectStringProperty = $ObjectStringProperty
            CommandInfo          = $CommandInfo
            RunspacePool         = $RunspacePool
            DebugOutputStream    = $DebugOutputStream
        }
        $AllThreads = Open-Thread @ThreadParameters
        Write-LogMsg @LogParams -Text "  # Received $(($AllThreads | Measure-Object).Count) threads from Open-Thread for $Command"
        Wait-Thread -Thread $AllThreads -Threads $Threads -SleepTimer $SleepTimer -Timeout $Timeout -Dispose -DebugOutputStream $DebugOutputStream -TodaysHostname $TodaysHostname
        $VerbosePreference = 'Continue'

        if ($Global:TimedOut -eq $false) {

            Write-LogMsg @LogParams -Text "  [System.Management.Automation.Runspaces.RunspacePool]::Close()"
            $null = $RunspacePool.Close()
            Write-LogMsg @LogParams -Text "  [System.Management.Automation.Runspaces.RunspacePool]::Close() completed"

            Write-LogMsg @LogParams -Text "  [System.Management.Automation.Runspaces.RunspacePool]::Dispose()"
            $null = $RunspacePool.Dispose()
            Write-LogMsg @LogParams -Text "  [System.Management.Automation.Runspaces.RunspacePool]::Dispose() completed"

        }

        Write-Progress -Activity 'Completed' -Completed

    }

}
