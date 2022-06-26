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
Get-PsCommandInfo [[-Command] <Object>]
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

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
