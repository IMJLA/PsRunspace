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
Add-PsModule -InitialSessionState <InitialSessionState> [[-ModuleInfo] <PSModuleInfo[]>] [<CommonParameters>]
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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
