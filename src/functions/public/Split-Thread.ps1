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

        # Set the preference variables for PowerShell output streams in each thread to match the current preferences
        $OutputStream = @('Debug', 'Verbose', 'Information', 'Warning', 'Error')
        ForEach ($ThisStream in $OutputStream) {
            if ($ThisStream -eq 'Error') {
                $VariableName = 'ErrorActionPreference'
            } else {
                $VariableName = "$($ThisStream)Preference"
            }
            $VariableValue = (Get-Variable -Name $VariableName).Value
            $variableEntry = [System.Management.Automation.Runspaces.SessionStateVariableEntry]::new($VariableName, $VariableValue, '')
            $InitialSessionState.Variables.Add($variableEntry)
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
