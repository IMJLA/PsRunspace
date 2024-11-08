---
Module Name: PsRunspace
Module Guid: bd092585-90cf-4df3-8d14-ee2b5bb548a6
Download Help Link: {{ Update Download Link }}
Help Version: 1.0.126
Locale: en-US
---

# PsRunspace Module
## Description
Module for multithreading PowerShell commands using .Net Runspaces

## PsRunspace Cmdlets
### [Add-PsCommand](docs/en-US/Add-PsCommand.md)
Add a command to a [System.Management.Automation.PowerShell] instance

### [Add-PsModule](docs/en-US/Add-PsModule.md)
Import a Module in a [System.Management.Automation.Runspaces.InitialSessionState] instance

### [Convert-FromPsCommandInfoToString](docs/en-US/Convert-FromPsCommandInfoToString.md)

Convert-FromPsCommandInfoToString [-CommandInfo] <psobject[]> [-DebugOutputStream <string>] [-TodaysHostname <string>] [-WhoAmI <string>] [-LogBuffer <hashtable>] [<CommonParameters>]


### [Expand-PsCommandInfo](docs/en-US/Expand-PsCommandInfo.md)
Return the original PsCommandInfo object as well as CommandInfo objects for any nested commands

### [Expand-PsToken](docs/en-US/Expand-PsToken.md)
Recursively get nested tokens

### [Get-PsCommandInfo](docs/en-US/Get-PsCommandInfo.md)
Get info about a PowerShell command

### [Open-Thread](docs/en-US/Open-Thread.md)
Prepares each thread so it is ready to execute a command and capture the output streams

### [Split-Thread](docs/en-US/Split-Thread.md)
Split a command for a collection of input objects into multiple threads for asynchronous processing

### [Wait-Thread](docs/en-US/Wait-Thread.md)
Waits for a thread to be completed so the results can be returned, or for a timeout to be reached


