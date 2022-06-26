---
external help file: PsRunspace-help.xml
Module Name: PsRunspace
online version:
schema: 2.0.0
---

# Open-Thread

## SYNOPSIS
Prepares each thread so it is ready to execute a command and capture the output streams

## SYNTAX

```
Open-Thread [[-InputObject] <Object>] [-RunspacePool] <RunspacePool> [[-ObjectStringProperty] <String>]
 [-Command] <Object> [[-CommandInfo] <PSObject>] [[-InputParameter] <String>] [[-AddParam] <Hashtable>]
 [[-AddSwitch] <String[]>] [<CommonParameters>]
```

## DESCRIPTION
Used by Split-Thread

For each InputObject an instance will be created of \[System.Management.Automation.PowerShell\]
Then a series of commands will be run to enable the specified output streams (all by default)

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -AddParam
Parameters to add to the Command
Each parameter is a name-value pair in the hashtable:
    @{"ParameterName" = "Value"}
    @{"ParameterName" = "Value" ; "ParameterTwo" = "Value2"}

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: @{}
Accept pipeline input: False
Accept wildcard characters: False
```

### -AddSwitch
Switches to add to the Command

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: @()
Accept pipeline input: False
Accept wildcard characters: False
```

### -Command
PowerShell Command or Script to run against each InputObject

```yaml
Type: System.Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CommandInfo
Output from Get-PsCommandInfo

```yaml
Type: System.Management.Automation.PSObject
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InputObject
Objects to pass to the Command as an argument or parameter

```yaml
Type: System.Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -InputParameter
Named parameter of the Command to pass InputObject to
If this is not specified, InputObject will be passed to the Command as an argument

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ObjectStringProperty
Name of a property (whose value is a string) that exists on each $InputObject
It will be used to represent the object in text form
If left null, the object's ToString() method will be used instead.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RunspacePool
{{ Fill RunspacePool Description }}

```yaml
Type: System.Management.Automation.Runspaces.RunspacePool
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
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
