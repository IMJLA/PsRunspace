---
external help file: PsRunspace-help.xml
Module Name: PsRunspace
online version:
schema: 2.0.0
---

# Get-PsCommandInfo

## SYNOPSIS
Get info about a PowerShell command

## SYNTAX

```
Get-PsCommandInfo [[-Command] <Object>] [[-DebugOutputStream] <String>] [[-TodaysHostname] <String>]
 [[-WhoAmI] <String>] [[-LogBuffer] <Hashtable>]
```

## DESCRIPTION
Used by Split-Thread, Invoke-Thread, and Add-PsCommand

Determine whether the Command is a \[System.Management.Automation.ScriptBlock\] object
If not, passes it to the Name parameter of Get-Command

## EXAMPLES

### EXAMPLE 1
```
The following demonstrates sending a Cmdlet name to the -Command parameter
    Get-PsCommandInfo -Command 'Write-Output'
```

## PARAMETERS

### -Command
Command to retrieve info on
This can be a scriptblock object, or a string that specifies an:
    Alias
    Function (the name of the function)
    ExternalScript (the path to the .ps1 file)
    All, Application, Cmdlet, Configuration, Filter, or Script

```yaml
Type: System.Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DebugOutputStream
Will be sent to the Type parameter of Write-LogMsg in the PsLogMessage module

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: Silent
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogBuffer
Hashtable of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: $Global:LogMessages
Accept pipeline input: False
Accept wildcard characters: False
```

### -TodaysHostname
Hostname to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: (HOSTNAME.EXE)
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhoAmI
Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: (whoami.EXE)
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
