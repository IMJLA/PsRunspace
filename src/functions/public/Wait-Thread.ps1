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
                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`t`$PowerShellInterface.Streams.ClearStreams()"
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

            Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`tStart-Sleep -Milliseconds `$SleepTimer"
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

            Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`t# $ActiveThreadCountString"
            Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`t# $($CompletedThreads.Count) completed threads"
            Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`t# $($CleanedUpThreads.Count) cleaned up threads"
            Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`t# $($IncompleteThreads.Count) incomplete threads"

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

                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`t# $($CompletedThread.PowerShellInterface.Streams.Progress.Count) Progress messages"
                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`t# $($CompletedThread.PowerShellInterface.Streams.Information.Count) Information messages"
                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`t# $($CompletedThread.PowerShellInterface.Streams.Verbose.Count) Verbose messages"
                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`t# $($CompletedThread.PowerShellInterface.Streams.Debug.Count) Debug messages"
                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`t# $($CompletedThread.PowerShellInterface.Streams.Warning.Count) Warning messages"

                # Because $Host was used to create the RunspacePool, any output to $Host (which includes Write-Host and Write-Information and Write-Progress) has already been displayed
                #$CompletedThread.PowerShellInterface.Streams.Progress | ForEach-Object {Write-Progress "$_"}
                #$CompletedThread.PowerShellInterface.Streams.Information | ForEach-Object { Write-Information "$_" }
                #$CompletedThread.PowerShellInterface.Streams.Verbose | ForEach-Object { Write-Verbose "$_" }
                #$CompletedThread.PowerShellInterface.Streams.Debug | ForEach-Object { Write-Debug "$_" }
                #$CompletedThread.PowerShellInterface.Streams.Warning | ForEach-Object { Write-Warning "$_" }

                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`t`$PowerShellInterface.Streams.ClearStreams()"
                $null = $CompletedThread.PowerShellInterface.Streams.ClearStreams()

                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`t`$PowerShellInterface.EndInvoke(`$Handle)"
                $ThreadOutput = $CompletedThread.PowerShellInterface.EndInvoke($CompletedThread.Handle)

                if ($Dispose -eq $true) {
                    <#NormallyCommentThisForPerformanceOptimization#>#if (($ThreadOutput | Measure-Object).Count -gt 0) {
                    <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`tOutput (count of $($ThreadOutput.Count)) received from thread $($CompletedThread.Index): $($CompletedThread.ObjectString)"
                    <#NormallyCommentThisForPerformanceOptimization#>#}
                    <#NormallyCommentThisForPerformanceOptimization#>#else {
                    <#NormallyCommentThisForPerformanceOptimization#>#Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`tNull result for thread $($CompletedThread.Index) ($($CompletedThread.ObjectString))"
                    <#NormallyCommentThisForPerformanceOptimization#>#}
                    $ThreadOutput
                    Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`t`$PowerShellInterface.Dispose()"
                    $null = $CompletedThread.PowerShellInterface.Dispose()
                    $CompletedThread.PowerShellInterface = $null
                    $CompletedThread.Handle = $null
                } else {
                    Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tWait-Thread`tThread $($CompletedThread.Index) ($($CompletedThread.ObjectString)) is finished opening."
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

        }

        $StopWatch.Stop()

        #NormallyCommentThisForPerformanceOptimization#Write-Verbose "$(Get-Date -Format s)`t$(hostname)`tWait-Thread`tFinished waiting for threads"
        Write-Progress -Activity 'Completed' -Completed

    }

}
