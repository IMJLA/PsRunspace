# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [1.0.126] - 2024-11-04 - convert log buffer to reference variable

## [1.0.124] - 2024-09-03 - kiss (fix bug introduced with unnecessary complexity)

## [1.0.123] - 2024-09-03 - add debug output

## [1.0.122] - 2024-09-03 - troubleshooting $input

## [1.0.121] - 2024-09-03 - add debug to confirm that the $input variable in the end block is not working

## [1.0.120] - 2024-09-03 - update Write-LogMsg param name from LogBuffer to Buffer

## [1.0.119] - 2024-05-26 - implement $input in split-thread to improve performance

## [1.0.118] - 2024-04-22 - update LogBuffer comment

## [1.0.117] - 2024-04-22 - rename LogMsgCache to LogBuffer

## [1.0.116] - 2024-04-22 - rename LogMsgCache to LogBuffer

## [1.0.115] - 2024-04-07 - implement progressparentid

## [1.0.114] - 2024-02-02 - add comments/future notesto expand-pscommandinfo

## [1.0.113] - 2024-01-31 - bugfix prog bars

## [1.0.112] - 2024-01-31 - make open-thread status text clearer

## [1.0.111] - 2024-01-31 - remove decimals from displayed progress percentage

## [1.0.110] - 2024-01-31 - bugfix prog bars

## [1.0.109] - 2024-01-31 - bugfix new progress bars

## [1.0.108] - 2024-01-31 - bugfix new progress bars

## [1.0.107] - 2024-01-31 - efficiency improvement for progress bars

## [1.0.106] - 2024-01-31 - updated progress bars

## [1.0.105] - 2024-01-28 - write-progress bugfix

## [1.0.104] - 2024-01-21 - enhancement-performance remove usage of select-object -first

## [1.0.103] - 2024-01-15 - removed some excessive overhead from Split-Thread

## [1.0.102] - 2024-01-14 - bugfix when 'Completed' activity not found by Write-Progress, now sending last used activity instead Open-Thread ln 255

## [1.0.101] - 2024-01-13 - testing cached git auth

## [1.0.100] - 2024-01-13 - bug fix related to addparameter vs addargument (addparameter doesn't work for Write-Output)

## [1.0.99] - 2023-02-06 - Updated example description in Expand-PsToken

## [1.0.98] - 2023-02-06 - Updated example description in Expand-PsToken

## [1.0.97] - 2023-02-06 - Updated example description in Expand-PsToken

## [1.0.96] - 2022-09-04 - Updated default for -Threads to use number of logical procs

## [1.0.95] - 2022-09-04 - Added throw statement on timeout

## [1.0.94] - 2022-08-27 - Fixed debug output for Start-Sleep in Wait-Thread

## [1.0.93] - 2022-08-25 - new psake task to fix readme

## [1.0.92] - 2022-08-19 - Added parameters for improved Write-LogMsg support

## [1.0.91] - 2022-08-17 - bug fix in Open-Thread when scriptblock has been constructed don't send CommandInfo to Add-PsCommand

## [1.0.90] - 2022-08-17 - improved debug output

## [1.0.89] - 2022-08-17 - improved debug output

## [1.0.88] - 2022-08-17 - bug fix in split-thread not loading definition of non-module functions

## [1.0.87] - 2022-08-17 - bug fix in split-thread not loading definition of non-module functions

## [1.0.86] - 2022-08-17 - bug fix in split-thread not loading definition of non-module functions

## [1.0.85] - 2022-08-17 - bug fix in split-thread not loading definition of non-module functions

## [1.0.84] - 2022-08-15 - Troubleshooting bug in Open-Thread

## [1.0.83] - 2022-08-15 - Bug fix in Add-PsCommandInfo

## [1.0.82] - 2022-08-15 - improved debug output of add-pscommand

## [1.0.81] - 2022-08-15 - Possible bug in Open-Thread?

## [1.0.80] - 2022-08-15 - Cannot decide on debug verbosity of Add-PsCommand

## [1.0.79] - 2022-08-14 - Implemented PsLogMessage module

## [1.0.78] - 2022-08-05 - Completed bug fix when Command is a ps1 file

## [1.0.77] - 2022-08-05 - Bugfix in Convert-FromPsCommandInfoToString

## [1.0.76] - 2022-08-05 - Bugfix when Command is a path to a .ps1 file

## [1.0.75] - 2022-07-30 - removed commented legacy code causing bug in open-thread...my fault for lazy find/replace en masse

## [1.0.74] - 2022-07-30 - Corrected indentation alignment on commented debug output lines

## [1.0.73] - 2022-07-30 - Commentd debug output in prep for merge back to main

## [1.0.72] - 2022-07-30 - Removed repetitive calls to hostname.exe per function; placed single calls in begin blocks instead

## [1.0.71] - 2022-07-30 - Commented some of the most verbose debug output

## [1.0.70] - 2022-07-30 - Removed AppendJoin() usage from Open-Thread for PS 5.1 compat

## [1.0.69] - 2022-07-30 - bugfix with ScriptDefinition.Append in Open-Thread

## [1.0.68] - 2022-07-30 - In Open-Thread, converted string to scriptblock to ensure AddScript instead of AddCommand by Add-PsCommand

## [1.0.67] - 2022-07-30 - Bug fix in new AddScript feature

## [1.0.66] - 2022-07-30 - Moved AddScript feature to begin block of Open-Thread for efficiency

## [1.0.65] - 2022-07-30 - bug fix with new addscript feature in open-thread

## [1.0.64] - 2022-07-30 - Implemented a single AddScript for loading all function definitions passed as PsCommandInfos

## [1.0.63] - 2022-07-30 - More uniform debug output messages

## [1.0.62] - 2022-07-30 - More uniform debug output messages

## [1.0.61] - 2022-07-30 - Enforced use of AddStatement() to see if it makes any difference

## [1.0.60] - 2022-07-30 - minor debug output adjustments

## [1.0.59] - 2022-07-30 - Added more debug verbosity

## [1.0.58] - 2022-07-30 - Trying .AddStatement().AddScript(...)

## [1.0.57] - 2022-07-30 - Trying .AddStatement().AddScript(...)

## [1.0.56] - 2022-07-30 - Added code to invoke each ps interface for function definitions to be preloaded (severe performance impact, need to rework to use Wait-Thread with dispose set to false)

## [1.0.55] - 2022-07-30 - Added detail to debug output

## [1.0.54] - 2022-07-30 - Commented non-powershell code in debug output

## [1.0.53] - 2022-07-30 - Added metadata to remaining debug output

## [1.0.52] - 2022-07-30 - Added metadata to remaining debug output

## [1.0.51] - 2022-07-30 - Minor bugfix in debug output for Open-Thread

## [1.0.50] - 2022-07-30 - Fixed a few write-debugs that needed metadata

## [1.0.49] - 2022-07-30 - Added metadata to debug output (forgot to save files last time...)

## [1.0.48] - 2022-07-30 - Added metadata to debug output

## [1.0.47] - 2022-07-30 - Updated debug output

## [1.0.46] - 2022-07-30 - Further improved debug output

## [1.0.45] - 2022-07-30 - more debug cleanup

## [1.0.44] - 2022-07-30 - Improved debug output

## [1.0.43] - 2022-07-30 - Updated Open-Therad debug output

## [1.0.42] - 2022-07-29 - Implemented Force switch in Add-PsCommand

## [1.0.41] - 2022-07-29 - test

## [1.0.40] - 2022-07-29 - Filtered out cmdlets from CommandInfo in split-thread

## [1.0.39] - 2022-07-29 - Forced string as var type for CommandType to address bug in Add-PsCommand

## [1.0.38] - 2022-07-29 - bug fix in get-pscommandinfo

## [1.0.37] - 2022-07-29 - Bug fix in the timeout feature of Wait-Thread where it was not setting the handle to null so the loop was not exiting

## [1.0.36] - 2022-07-29 - Re-enabled all debug output to resume troubleshooting ps5.1 problems

## [1.0.35] - 2022-07-29 - No really this time all the debug output is gone

## [1.0.34] - 2022-07-29 - I swear now I must have commented all the debug output

## [1.0.33] - 2022-07-29 - Commented more debug output

## [1.0.32] - 2022-07-29 - Commented all debug output

## [1.0.31] - 2022-07-29 - Bug fix in split-thread

## [1.0.30] - 2022-07-29 - test with extra debug output

## [1.0.29] - 2022-07-29 - testing again

## [1.0.28] - 2022-07-29 - Troubleshooting continues

## [1.0.27] - 2022-07-29 - Bug fixes related to CommandInfo vs PsCommandInfo

## [1.0.26] - 2022-07-29 - bug fix in split-thread again

## [1.0.25] - 2022-07-29 - Bug fix in split-thread when filtering commandinfo

## [1.0.24] - 2022-07-29 - Troubleshooting Add-PsCommand

## [1.0.23] - 2022-07-29 - bug fix incorrect param name for add-psmodule in split-thread

## [1.0.22] - 2022-07-29 - Improved process of loading all necessary modules into initialsessionstate in split-thread

## [1.0.23] - 2022-07-29 - Troubleshooting Wait-Thread

## [1.0.22] - 2022-07-29 - Trying to fix bugs in Add-PsCommand

## [1.0.21] - 2022-07-29 - bug fixes with Split-Path to remove unnecessary pipeline overhead

## [1.0.20] - 2022-07-29 - Test build to troubleshoot 5.1 compatibility

## [1.0.19] - 2022-07-25 - Cleaned up source .psm1 file

## [1.0.18] - 2022-07-10 - Publish to PSGallery

## [1.0.17] - 2022-07-10 - Updated ReadMe

## [1.0.16] - 2022-06-25 - ImportPSModulesFromPath is more intelligent than ImportPSModule because it will use a manifest if available

## [1.0.15] - 2022-06-25 - Efficiency improvement in Split-Thread

## [1.0.14] - 2022-06-25 - Minor cleanup and efficiency improvements

## [1.0.13] - 2022-06-25 - Minor cleanup and efficiency improvements

## [1.0.12] - 2022-06-25 - Removed OutputStream param from Split-Thread in favor of honoring preference variables

## [1.0.11] - 2022-06-23 - Fixed module manifest

## [1.0.10] - 2022-06-23 - Updated tests

## [1.0.9] - 2022-06-23 - Version 1.0

## [1.0.8] - 2022-06-23 - Version 1.0

## [1.0.7] - 2022-06-23 - Version 1.0

## [1.0.6] - 2022-06-23 - Forcing git push

## [1.0.5] - 2022-06-23 - Resolved bug in source module causing it to retrieve test files and treat them as source code

## [1.0.4] - 2022-06-23 - Reproducing build error

## [1.0.3] - 2022-06-22 - troubleshooting build process

## [1.0.2] - 2022-06-22 - Troubleshooting broken build process

## [1.0.1] - 2022-06-21 - Testing build script

## [1.0.0] Unreleased

