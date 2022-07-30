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
                Write-Debug "Add-PsCommand -Command $($ThisCommandInfo.CommandInfo.Name) -CommandInfo `$ThisCommandInfo -PowershellInterface `$PowershellInterface"
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
            <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tOpen-Thread`t$StatusString"
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
