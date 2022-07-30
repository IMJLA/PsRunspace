---
Module Name: PsRunspace
Module Guid: bd092585-90cf-4df3-8d14-ee2b5bb548a6 bd092585-90cf-4df3-8d14-ee2b5bb548a6
Download Help Link: {{ Update Download Link }}
Help Version: 1.0.38
Locale: en-US
---

# PsRunspace Module
## Description
Module for multithreading PowerShell commands using .Net Runspaces

## PsRunspace Cmdlets
### [Add-PsCommand](Add-PsCommand.md)
Add a command to a [System.Management.Automation.PowerShell] instance

### [Add-PsModule](Add-PsModule.md)
Import a Module in a [System.Management.Automation.Runspaces.InitialSessionState] instance

### [Expand-PsCommandInfo](Expand-PsCommandInfo.md)
Return the original PsCommandInfo object as well as CommandInfo objects for any nested commands

### [Expand-PsToken](Expand-PsToken.md)
Recursively get nested tokens

### [Get-PsCommandInfo](Get-PsCommandInfo.md)
Get info about a PowerShell command

### [Open-Thread](Open-Thread.md)
Prepares each thread so it is ready to execute a command and capture the output streams

### [Split-Thread](Split-Thread.md)
Split a command for a collection of input objects into multiple threads for asynchronous processing

### [Wait-Thread](Wait-Thread.md)
Waits for a thread to be completed so the results can be returned, or for a timeout to be reached


