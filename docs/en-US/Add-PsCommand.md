---
external help file: PsRunspace-help.xml
Module Name: PsRunspace
online version:
schema: 2.0.0
---

# Add-PsCommand

## SYNOPSIS
Add a command to a \[System.Management.Automation.PowerShell\] instance

## SYNTAX

```
Add-PsCommand [-PowershellInterface <PowerShell[]>] [[-Command] <Object>] [-CommandInfo <PSObject>] [-Force]
 [-DebugOutputStream <String>] [-TodaysHostname <String>] [-WhoAmI <String>] [-LogBuffer <Hashtable>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Used by Invoke-Thread
Uses AddScript() or AddStatement() and AddCommand() depending on the command

## EXAMPLES

### EXAMPLE 1
```
[powershell]::Create() | Add-PsCommand -Command 'Write-Output'
```

Add a command by sending a Cmdlet name to the -Command parameter

## PARAMETERS

### -Command
Command to add to the Powershell interface
This can be a scriptblock object, or a string that specifies a:
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

### -CommandInfo
Output from Get-PsCommandInfo
Optional, to improve performance if it will be re-used for multiple calls of Add-PsCommand

```yaml
Type: System.Management.Automation.PSObject
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
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
Position: Named
Default value: Silent
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Add Commands rather than their definitions

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
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
Position: Named
Default value: $Global:LogMessages
Accept pipeline input: False
Accept wildcard characters: False
```

### -PowershellInterface
Powershell interface to add the Command to

```yaml
Type: System.Management.Automation.PowerShell[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
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
