---
external help file: PsRunspace-help.xml
Module Name: PsRunspace
online version:
schema: 2.0.0
---

# Add-PsModule

## SYNOPSIS
Import a Module in a \[System.Management.Automation.Runspaces.InitialSessionState\] instance

## SYNTAX

```
Add-PsModule -InitialSessionState <InitialSessionState> [[-ModuleInfo] <PSModuleInfo[]>]
 [-DebugOutputStream <String>] [-TodaysHostname <String>] [-WhoAmI <String>] [-LogMsgCache <Hashtable>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Used by Add-PsCommand
Uses ImportPSModule() or ImportPSModulesFromPath() depending on the module

## EXAMPLES

### EXAMPLE 1
```
$InitialSessionState = [system.management.automation.runspaces.initialsessionstate]::CreateDefault()
Add-PsModule -InitialSessionState $InitialSessionState -ModuleInfo $ModuleInfo
```

## PARAMETERS

### -DebugOutputStream
Will be sent to the Type parameter of Write-LogMsg in the PsLogMessage module

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Silent
Accept pipeline input: False
Accept wildcard characters: False
```

### -InitialSessionState
Powershell interface to add the Command to

```yaml
Type: System.Management.Automation.Runspaces.InitialSessionState
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogMsgCache
Hashtable of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: $Global:LogMessages
Accept pipeline input: False
Accept wildcard characters: False
```

### -ModuleInfo
ModuleInfo object for the module to add to the Powershell interface

```yaml
Type: System.Management.Automation.PSModuleInfo[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: System.Management.Automation.ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
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
Position: Named
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
Position: Named
Default value: (whoami.EXE)
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
