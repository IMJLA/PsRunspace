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

        $InitialSessionState = [system.management.automation.runspaces.initialsessionstate]::CreateDefault()

        # Import the source module containing the specified Command in each thread
        $CommandInfo = Get-PsCommandInfo -Command $Command
        switch ($CommandInfo.ModuleInfo.ModuleType) {
            'Binary' {
                Write-Debug "`$InitialSessionState.ImportPSModule('$($CommandInfo.ModuleInfo.Name)')"
                $InitialSessionState.ImportPSModule($CommandInfo.ModuleInfo.Name)
            }
            'Script' {
                $ModulePath = $CommandInfo.ModuleInfo.Path | Split-Path -Parent
                Write-Debug "`$InitialSessionState.ImportPSModulesFromPath('$ModulePath')"
                $InitialSessionState.ImportPSModulesFromPath($ModulePath)
            }
            'Manifest' {
                $ModulePath = $CommandInfo.ModuleInfo.Path | Split-Path -Parent
                Write-Debug "`$InitialSessionState.ImportPSModulesFromPath('$ModulePath')"
                $InitialSessionState.ImportPSModulesFromPath($ModulePath)
            }
            default {
                # Scriptblocks have no module to import so ModuleInfo will be null
            }
        }

        # Import any additional specified modules in each thread
        ForEach ($Module in $AddModule) {

            $ModuleObj = Get-Module $Module -ErrorAction SilentlyContinue
            switch ($ModuleObj.ModuleType) {
                'Binary' {
                    Write-Debug "`$InitialSessionState.ImportPSModule('$Module')"
                    $InitialSessionState.ImportPSModule($Module)
                }
                default {
                    # This is for Script or Manifest modules
                    Write-Debug "`$InitialSessionState.ImportPSModulesFromPath('$($ModuleObj.Path | Split-Path -Parent)')"
                    $InitialSessionState.ImportPSModulesFromPath(($ModuleObj.Path | Split-Path -Parent))

                }
            }

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

        $RunspacePool = [runspacefactory]::CreateRunspacePool(1, $Threads, $InitialSessionState, $Host)
        $VerbosePreference = 'SilentlyContinue'
        $RunspacePool.Open()

        $Global:TimedOut = $false

        $AllInputObjects = [System.Collections.Generic.List[psobject]]::new()

    }

    process {

        # Add all the input objects from the pipeline to a single collection; allows progress bars later
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
            ObjectStringProperty = $ObjectStringProperty
            CommandInfo          = $CommandInfo
            RunspacePool         = $RunspacePool
        }
        $AllThreads = Open-Thread @ThreadParameters
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
