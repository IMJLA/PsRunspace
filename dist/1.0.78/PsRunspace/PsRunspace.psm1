
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
        [pscustomobject]$CommandInfo,

        # Add Commands rather than their definitions
        [switch]$Force

    )

    begin {

        if ($CommandInfo -eq $null) {
            $CommandInfo = Get-PsCommandInfo -Command $Command
        }

        $TodaysHostname = HOSTNAME.EXE

    }
    process {

        ForEach ($ThisPowershell in $PowershellInterface) {

            switch ($CommandInfo.CommandType) {

                'Alias' {
                    # Resolve the alias to its command and start from the beginning with that command.
                    $CommandInfo = Get-PsCommandInfo -Command $CommandInfo.CommandInfo.Definition
                    $null = Add-PsCommand -Command $CommandInfo.CommandInfo.Definition -CommandInfo $CommandInfo -PowershellInterface $ThisPowerShell
                }
                'Function' {

                    if ($Force) {
                        <#NormallyCommentThisForPerformanceOptimization#>###Write-Debug "Add-PsCommand adding command '$Command' of type '$($CommandInfo.CommandType)'"
                        # If the type is All, Application, Cmdlet, Configuration, Filter, or Script then run the command as-is
                        <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tAdd-PsCommand`t`$PowershellInterface.AddStatement().AddCommand('$Command')"
                        $null = $ThisPowershell.AddStatement().AddCommand($Command)
                    } else {
                        # Add the definitions of the function
                        # BUG: Look at the definition of Get-Member for example, it is not in a ScriptModule so its definition is not PowerShell code
                        [string]$ThisFunction = "function $($CommandInfo.CommandInfo.Name) {`r`n$($CommandInfo.CommandInfo.Definition)`r`n}"
                        <#NormallyCommentThisForPerformanceOptimization#>###Write-Debug "Add-PsCommand adding Script (the Definition of a Function)"
                        <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tAdd-PsCommand`t`$PowershellInterface.AddScript('function $($CommandInfo.CommandInfo.Name) {...}') # Function definition not expanded in debug message for brevity"
                        $null = $ThisPowershell.AddScript($ThisFunction)
                    }
                }
                'ExternalScript' {
                    <#NormallyCommentThisForPerformanceOptimization#>###Write-Debug "Add-PsCommand adding Script (the ScriptBlock of an ExternalScript)"
                    <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tAdd-PsCommand`t`$PowershellInterface.AddScript(`"$($CommandInfo.ScriptBlock)`") # `$CommandInfo.ScriptBlock not expanded in debug message for brevity"
                    $null = $ThisPowershell.AddScript($CommandInfo.ScriptBlock)
                }
                'ScriptBlock' {
                    <#NormallyCommentThisForPerformanceOptimization#>###Write-Debug "Add-PsCommand adding Script (a ScriptBlock)"
                    <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tAdd-PsCommand`t`$PowershellInterface.AddScript('$Command')"
                    <#NormallyCommentThisForPerformanceOptimization#>##Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tAdd-PsCommand`t`$PowershellInterface.AddScript(`"`$Command`") # `$Command variable not expanded in debug message for brevity"
                    $null = $ThisPowershell.AddScript($Command)
                }
                default {
                    <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tAdd-PsCommand`t# Adding command '$Command' of type '$($CommandInfo.CommandType)'"
                    # If the type is All, Application, Cmdlet, Configuration, Filter, or Script then run the command as-is
                    <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tAdd-PsCommand`t`$PowershellInterface.AddStatement().AddCommand('$Command')"
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
            Position = 0
        )]
        [System.Management.Automation.PSModuleInfo[]]$ModuleInfo

    )

    begin {

        $TodaysHostname = HOSTNAME.EXE

    }

    process {

        ForEach ($ThisModule in $ModuleInfo) {

            switch ($ThisModule.ModuleType) {
                'Binary' {
                    <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tAdd-PsModule`t`$InitialSessionState.ImportPSModule('$($ThisModule.Name)')"
                    $InitialSessionState.ImportPSModule($ThisModule.Name)
                }
                'Script' {
                    $ModulePath = Split-Path -Path $ThisModule.Path -Parent
                    <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tAdd-PsModule`t`$InitialSessionState.ImportPSModulesFromPath('$ModulePath')"
                    $InitialSessionState.ImportPSModulesFromPath($ModulePath)
                }
                'Manifest' {
                    $ModulePath = Split-Path -Path $ThisModule.Path -Parent
                    <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tAdd-PsModule`t`$InitialSessionState.ImportPSModulesFromPath('$ModulePath')"
                    $InitialSessionState.ImportPSModulesFromPath($ModulePath)
                }
                default {
                    # Scriptblocks or Functions not from modules will have no module to import so ModuleInfo will be null
                }

            }

        }

    }

}
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
    if (-not $PsCommandInfo.CommandInfo.Name) {
        $PsCommandInfo
    } else {
        $Cache[$PsCommandInfo.CommandInfo.Name] = $PsCommandInfo
    }

    # Tokenize the function definition
    $PsTokens = $null
    $TokenizerErrors = $null
    $AbstractSyntaxTree = [System.Management.Automation.Language.Parser]::ParseInput(
        # We need the property which contains tokenizable PowerShell
        # For a function in a ScriptModule, the definition and scriptblock properties are the same
        # For an ExternalScript, the definition is the filepath and the scriptblock is tokenizable powershell
        # This is why the Scriptblock property has been chosen
        #$PsCommandInfo.CommandInfo.Definition,
        $PsCommandInfo.CommandInfo.Scriptblock,
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
        [string]$CommandType = 'ScriptBlock'
    } else {
        $CommandInfo = Get-Command $Command -ErrorAction SilentlyContinue
        [string]$CommandType = $CommandInfo.CommandType
        if ($CommandInfo.Source -like "*\*") {
            $ModuleInfo = Get-Module -Name $CommandInfo.Source -ListAvailable -ErrorAction SilentlyContinue
        } else {
            if ($CommandInfo.Source) {
                <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tGet-PsCommandInfo`tGet-Module -Name '$($CommandInfo.Source)'"
                $ModuleInfo = Get-Module -Name $CommandInfo.Source -ErrorAction SilentlyContinue
            }
        }
    }

    if ($ModuleInfo.Path -like "*.ps1") {
        $ModuleInfo = $null
        $SourceModuleName = $null
    } else {
        $SourceModuleName = $CommandInfo.Source
    }

    #CommentedForPerformanceOptimization#Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGet-PsCommandInfo`t$Command is a $CommandType"
    [pscustomobject]@{
        CommandInfo            = $CommandInfo
        ModuleInfo             = $ModuleInfo
        CommandType            = $CommandType
        SourceModuleDefinition = $ModuleInfo.Definition
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

        $TodaysHostname = HOSTNAME.EXE
        [int64]$CurrentObjectIndex = 0
        $ThreadCount = @($InputObject).Count
        <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tOpen-Thread`t# Received $(($CommandInfo | Measure-Object).Count) PsCommandInfos from Split-Thread for '$Command'"

        if ($CommandInfo) {

            # Begin to build the command that the script will run with all its parameters
            if (Test-Path $Command -ErrorAction SilentlyContinue) {
                # If $Command is a valid file path, dot-source it and wrap it in single quotes to handle spaces
                $CommandStringForScriptDefinition = [System.Text.StringBuilder]::new(". '$Command'")
            } else {
                $CommandStringForScriptDefinition = [System.Text.StringBuilder]::new($Command)
            }

            # Build the param block of the script. Along the way, add any necessary parameters and switches
            # Avoided using AppendJoin for slight performance and code readability penalty due to lack of support in PS 5.1
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
            Convert-FromPsCommandInfoToString -CommandInfo $CommandInfo |
            ForEach-Object {
                $null = $ScriptDefinition.AppendLine("`r`n$_")
            }
            $null = $ScriptDefinition.AppendLine()
            $CommandStringForScriptDefinition |
            ForEach-Object {
                $null = $ScriptDefinition.AppendLine("`r`n$_")
            }
            $null = $ScriptDefinition.AppendLine()
            $ScriptString = $ScriptDefinition.ToString()

            # Remove blank lines
            # Commented out due to risk of unintended side effects: what if the code includes a here-string that requires blank lines, etc)
            #while ( $ScriptString -match '\r\n\r\n' ) {
            #    $ScriptString = $ScriptString -replace "`r`n`r`n", "`r`n"
            #}

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

            <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tOpen-Thread`t`$PowershellInterface = [powershell]::Create() # for '$Command' on '$ObjectString'"
            $PowershellInterface = [powershell]::Create()

            <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tOpen-Thread`t`$PowershellInterface.RunspacePool = `$RunspacePool # for '$Command' on '$ObjectString'"
            $PowershellInterface.RunspacePool = $RunspacePool

            # Do I need this one?  What commands would be in there?
            <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tOpen-Thread`t`$PowershellInterface.Commands.Clear() # for '$Command' on '$ObjectString'"
            $null = $PowershellInterface.Commands.Clear()

            if ($ScriptBlock) {
                $null = Add-PsCommand -Command $ScriptBlock -PowershellInterface $PowershellInterface -Force
            } else {
                $null = Add-PsCommand -Command $Command -PowershellInterface $PowershellInterface -Force
            }

            # Prepare to pass $InputObject into the runspace as a parameter not an argument
            # Do this even if we end up passing it as an argument to the command inside the runspace
            If ([string]::IsNullOrEmpty($InputParameter)) {
                $InputParameter = 'PsRunspaceArgument1'
            }

            <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tOpen-Thread`t`$PowershellInterface.AddParameter('$InputParameter', '$ObjectString') # for '$Command' on '$ObjectString'"
            $null = $PowershellInterface.AddParameter($InputParameter, $Object)
            <#NormallyCommentThisForPerformanceOptimization#>$InputParameterStringForDebug = "-$InputParameter '$ObjectString'"


            $AdditionalParameters = @()
            $AdditionalParameters = ForEach ($Key in $AddParam.Keys) {
                <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tOpen-Thread`t`$PowershellInterface.AddParameter('$Key', '$($AddParam.$key)') # for '$Command' on '$ObjectString'"
                $null = $PowershellInterface.AddParameter($Key, $AddParam.$key)
                <#NormallyCommentThisForPerformanceOptimization#>"-$Key '$($AddParam.$key)'"
            }
            $AdditionalParametersString = $AdditionalParameters -join ' '

            $Switches = @()
            $Switches = ForEach ($Switch in $AddSwitch) {
                <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tOpen-Thread`t`$PowershellInterface.AddParameter('$Switch') # for '$Command' on '$ObjectString'"
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

            <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tOpen-Thread`t`$Handle = `$PowershellInterface.BeginInvoke() # for '$Command' on '$ObjectString'"
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

        $TodaysHostname = HOSTNAME.EXE
        <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tSplit-Thread`t# Entered begin block for '$Command'"

        <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tSplit-Thread`t`$InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault() # for '$Command'"
        $InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()

        # Import the source module containing the specified Command in each thread

        $OriginalCommandInfo = Get-PsCommandInfo -Command $Command
        <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tSplit-Thread`t# Found 1 original PsCommandInfo for '$Command'"

        $CommandInfo = Expand-PsCommandInfo -PsCommandInfo $OriginalCommandInfo
        <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tSplit-Thread`t# Found $(($CommandInfo | Measure-Object).Count) nested PsCommandInfos for '$Command' ($($CommandInfo.CommandInfo.Name -join ','))"

        # Prepare our collection of PowerShell modules to import in each thread
        # This will include any modules specified by name with the -AddModule parameter
        $ModulesToAdd = [System.Collections.Generic.List[System.Management.Automation.PSModuleInfo]]::new()
        ForEach ($Module in $AddModule) {
            <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tSplit-Thread`tGet-Module -Name '$Module'"
            $ModuleObj = Get-Module -Name $Module -ErrorAction SilentlyContinue
            $null = $ModulesToAdd.Add($ModuleObj)
        }

        # This will also include any modules identified by tokenizing the -Command parameter or its definition, and recursing through all nested command tokens
        $CommandInfo.ModuleInfo |
        Sort-Object -Property Name -Unique |
        ForEach-Object {
            $null = $ModulesToAdd.Add($_)
        }

        $CommandInfo = $CommandInfo |
        Where-Object -FilterScript {
            $ModulesToAdd.Name -notcontains $_.ModuleInfo.Name -and
            $_.CommandType -ne 'Cmdlet'
        }
        <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tSplit-Thread`t# Found $(($CommandInfo | Measure-Object).Count) remaining PsCommandInfos to define for '$Command' (not in modules: $($CommandInfo.CommandInfo.Name -join ','))"

        if ($ModulesToAdd.Count -gt 0) {
            $null = Add-PsModule -InitialSessionState $InitialSessionState -ModuleInfo $ModulesToAdd
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

        <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tSplit-Thread`t`$RunspacePool = [runspacefactory]::CreateRunspacePool(1, $Threads, `$InitialSessionState, `$Host) # for '$Command'"
        $RunspacePool = [runspacefactory]::CreateRunspacePool(1, $Threads, $InitialSessionState, $Host)
        #####don'trememberwhythisishere#####$VerbosePreference = 'SilentlyContinue'
        <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tSplit-Thread`t`$RunspacePool.Open() # for '$Command'"
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
        <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tSplit-Thread`t# Entered process block for '$Command' on '$ObjectString'"

        # Add all the input objects from the pipeline to a single collection; allows progress bars later
        ForEach ($ThisObject in $InputObject) {
            $null = $AllInputObjects.Add($ThisObject)
        }

    }
    end {
        <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tSplit-Thread`t# Entered end block for '$Command'"
        <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tSplit-Thread`t# Sending $(($CommandInfo | Measure-Object).Count) PsCommandInfos to Open-Thread for '$Command'"
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
        <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tSplit-Thread`t# Received $(($AllThreads | Measure-Object).Count) threads from Open-Thread for $Command"
        Wait-Thread -Thread $AllThreads -Threads $Threads -SleepTimer $SleepTimer -Timeout $Timeout -Dispose
        $VerbosePreference = 'Continue'

        if ($Global:TimedOut -eq $false) {

            #CommentedForPerformanceOptimization#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tSplit-Thread`t[System.Management.Automation.Runspaces.RunspacePool]::Close()"
            $null = $RunspacePool.Close()
            #CommentedForPerformanceOptimization#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tSplit-Thread`t[System.Management.Automation.Runspaces.RunspacePool]::Close() completed"

            #CommentedForPerformanceOptimization#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tSplit-Thread`t[System.Management.Automation.Runspaces.RunspacePool]::Dispose()"
            $null = $RunspacePool.Dispose()
            #CommentedForPerformanceOptimization#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tSplit-Thread`t[System.Management.Automation.Runspaces.RunspacePool]::Dispose() completed"

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

        $TodaysHostname = HOSTNAME.EXE

    }

    process {

        ForEach ($ThisThread in $Thread) {

            # If the threads do not have handles, there is nothing to wait for, so output the thread as-is.
            # Otherwise wait for the handle to indicate completion (or a timeout to be reached)
            if ($ThisThread.Handle -eq $false) {
                <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tWait-Thread`t`$PowerShellInterface.Streams.ClearStreams() # for '$CommandString' on '$($ThisThread.ObjectString)'"
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

            <#NormallyCommentThisForPerformanceOptimization#>###Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tWait-Thread`tStart-Sleep -Milliseconds `$SleepTimer # for '$CommandString'"
            Start-Sleep -Milliseconds $SleepTimer

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

            <#NormallyCommentThisForPerformanceOptimization#>##Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tWait-Thread`t# $ActiveThreadCountString for '$CommandString'"
            <#NormallyCommentThisForPerformanceOptimization#>##Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tWait-Thread`t# $($CompletedThreads.Count) completed threads for '$CommandString'"
            <#NormallyCommentThisForPerformanceOptimization#>##Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tWait-Thread`t# $($CleanedUpThreads.Count) cleaned up threads for '$CommandString'"
            <#NormallyCommentThisForPerformanceOptimization#>##Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tWait-Thread`t# $($IncompleteThreads.Count) incomplete threads for '$CommandString'"

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

                # TODO: Debug these counts, something seems off, they vary wildly with Test-Multithreading.ps1 but I would expect consistency (same number of Warnings per thread)
                <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tWait-Thread`t# $($CompletedThread.PowerShellInterface.Streams.Progress.Count) Progress messages for '$CommandString' on '$($CompletedThread.ObjectString)'"
                <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tWait-Thread`t# $($CompletedThread.PowerShellInterface.Streams.Information.Count) Information messages for '$CommandString' on '$($CompletedThread.ObjectString)'"
                <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tWait-Thread`t# $($CompletedThread.PowerShellInterface.Streams.Verbose.Count) Verbose messages for '$CommandString' on '$($CompletedThread.ObjectString)'"
                <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tWait-Thread`t# $($CompletedThread.PowerShellInterface.Streams.Debug.Count) Debug messages for '$CommandString' on '$($CompletedThread.ObjectString)'"
                <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tWait-Thread`t# $($CompletedThread.PowerShellInterface.Streams.Warning.Count) Warning messages for '$CommandString' on '$($CompletedThread.ObjectString)'"

                # Because $Host was used to create the RunspacePool, any output to $Host (which includes Write-Host and Write-Information and Write-Progress) has already been displayed
                #$CompletedThread.PowerShellInterface.Streams.Progress | ForEach-Object {Write-Progress "$_"}
                #$CompletedThread.PowerShellInterface.Streams.Information | ForEach-Object { Write-Information "$_" }
                #$CompletedThread.PowerShellInterface.Streams.Verbose | ForEach-Object { Write-Verbose "$_" }
                #$CompletedThread.PowerShellInterface.Streams.Debug | ForEach-Object { Write-Debug "$_" }
                #$CompletedThread.PowerShellInterface.Streams.Warning | ForEach-Object { Write-Warning "$_" }

                <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tWait-Thread`t`$PowerShellInterface.Streams.ClearStreams() # for '$CommandString' on '$($CompletedThread.ObjectString)'"
                $null = $CompletedThread.PowerShellInterface.Streams.ClearStreams()

                <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tWait-Thread`t`$PowerShellInterface.EndInvoke(`$Handle) # for '$CommandString' on '$($CompletedThread.ObjectString)'"
                $ThreadOutput = $CompletedThread.PowerShellInterface.EndInvoke($CompletedThread.Handle)

                if ($Dispose -eq $true) {
                    <#NormallyCommentThisForPerformanceOptimization#>##if (($ThreadOutput | Measure-Object).Count -gt 0) {
                    <#NormallyCommentThisForPerformanceOptimization#>##Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tWait-Thread`tOutput (count of $($ThreadOutput.Count)) received from thread $($CompletedThread.Index): $($CompletedThread.ObjectString)"
                    <#NormallyCommentThisForPerformanceOptimization#>##}
                    <#NormallyCommentThisForPerformanceOptimization#>##else {
                    <#NormallyCommentThisForPerformanceOptimization#>##Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tWait-Thread`tNull result for thread $($CompletedThread.Index) ($($CompletedThread.ObjectString))"
                    <#NormallyCommentThisForPerformanceOptimization#>##}
                    $ThreadOutput
                    <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tWait-Thread`t`$PowerShellInterface.Dispose() # for '$CommandString' on '$($CompletedThread.ObjectString)'"
                    $null = $CompletedThread.PowerShellInterface.Dispose()
                    $CompletedThread.PowerShellInterface = $null
                    $CompletedThread.Handle = $null
                } else {
                    <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$TodaysHostname`tWait-Thread`tThread $($CompletedThread.Index) is finished opening for '$CommandString' on '$($CompletedThread.ObjectString)'"
                    $CompletedThread.Handle = $null
                    $CompletedThread
                }

                $StopWatch.Reset()
                $StopWatch.Start()

            }

            If ($StopWatch.ElapsedMilliseconds / 1000 -gt $Timeout) {

                Write-Warning "$(Get-Date -Format s)`t$TodaysHostname`tWait-Thread`tReached Timeout of $Timeout seconds. Skipping $($IncompleteThreads.Count) remaining threads: $RemainingString"

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

        }

        $StopWatch.Stop()

        #NormallyCommentThisForPerformanceOptimization#Write-Verbose "$(Get-Date -Format s)`t$TodaysHostname`tWait-Thread`tFinished waiting for threads"
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
Export-ModuleMember -Function @('Add-PsCommand','Add-PsModule','Convert-FromPsCommandInfoToString','Expand-PsCommandInfo','Expand-PsToken','Get-PsCommandInfo','Open-Thread','Split-Thread','Wait-Thread')



















