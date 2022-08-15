---
external help file: PsRunspace-help.xml
Module Name: PsRunspace
online version:
schema: 2.0.0
---

# Expand-PsCommandInfo

## SYNOPSIS
Return the original PsCommandInfo object as well as CommandInfo objects for any nested commands

## SYNTAX

```
Expand-PsCommandInfo [[-PsCommandInfo] <PSObject>] [[-Cache] <Hashtable>] [[-DebugOutputStream] <String>]
 [[-TodaysHostname] <String>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -Cache
Cache of already identified CommmandInfo objects

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: [hashtable]::Synchronized(@{})
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
Position: 3
Default value: Silent
Accept pipeline input: False
Accept wildcard characters: False
```

### -PsCommandInfo
CommandInfo object for the command whose nested command names to return

```yaml
Type: System.Management.Automation.PSObject
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TodaysHostname
{{ Fill TodaysHostname Description }}

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: (HOSTNAME.EXE)
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
