---
external help file: PsRunspace-help.xml
Module Name: PsRunspace
online version:
schema: 2.0.0
---

# Split-Thread

## SYNOPSIS
Split a command for a collection of input objects into multiple threads for asynchronous processing

## SYNTAX

```
Split-Thread [-Command] <Object> [[-InputObject] <Object>] [[-InputParameter] <Object>] [[-Threads] <Int32>]
 [[-SleepTimer] <Int32>] [[-Timeout] <Int32>] [[-AddParam] <Hashtable>] [[-AddSwitch] <String[]>]
 [[-AddModule] <String[]>] [[-ObjectStringProperty] <String>] [[-DebugOutputStream] <String>]
 [[-TodaysHostname] <String>] [[-WhoAmI] <String>] [-LogBuffer] <PSReference> [[-ProgressParentId] <Int32>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The specified command will be run for each input object in a separate powershell instance with its own runspace
These runspaces are part of the same runspace pool inside the same powershell.exe process

## EXAMPLES

### EXAMPLE 1
```
The following demonstrates sending a Cmdlet name to the -Command parameter
    $InputObject | Split-Thread -Command 'Write-Output'
```

### EXAMPLE 2
```
The following demonstrates sending a scriptblock to the -Command parameter
    $InputObject | Split-Thread -Command [scriptblock]::create("Write-Output `$args[0]")
```

### EXAMPLE 3
```
The following demonstrates sending a script file path to the -Command parameter
    $InputObject | Split-Thread -Command "C:\Test-Command.ps1"
```

### EXAMPLE 4
```
The following demonstrates sending a function to the -Command parameter
    $InputObject | Split-Thread -Command 'Test-Function'
```

### EXAMPLE 5
```
The following demonstrates the -AddParam parameter
```

$InputObject | Split-Thread -Command "Get-Service" -InputParameter ComputerName -AddParam @{"Name" = "BITS"}

### EXAMPLE 6
```
The following demonstrates the -AddSwitch parameter
```

$InputObject | Split-Thread -Command "Get-Service" -AddSwitch @('RequiredServices','DependentServices')

### EXAMPLE 7
```
The following demonstrates the use of a threadsafe hashtable to store results
The hastable can be accessed and updated from inside each runspace
```

$ThreadsafeHashtable = \[hashtable\]::Synchronized(@{})
$InputObject | Split-Thread -Command "Fake-Function" -InputParameter ComputerName -AddParam @{"ResultHashTableParameter" = $ThreadsafeHashtable}

## PARAMETERS

### -AddModule
Names of modules to import in each runspace

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 9
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

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
Position: 11
Default value: Silent
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
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -InputParameter
Named parameter of the Command to pass InputObject to
If this is not specified, InputObject will be passed to the Command as an argument

```yaml
Type: System.Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogBuffer
Log messages which have not yet been written to disk

```yaml
Type: System.Management.Automation.PSReference
Parameter Sets: (All)
Aliases:

Required: True
Position: 14
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ObjectStringProperty
Name of a property (whose value is a string) that exists on each $InputObject and can be used to represent the object in text form
If left null, the object's ToString() method will be used instead.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 10
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

### -ProgressParentId
ID of the parent progress bar under which to show progres

```yaml
Type: System.Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 15
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -SleepTimer
Milliseconds to wait between cycles of the loop that checks threads for completion

```yaml
Type: System.Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: 200
Accept pipeline input: False
Accept wildcard characters: False
```

### -Threads
Maximum number of concurrent threads to allow

```yaml
Type: System.Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: (Get-CimInstance -ClassName CIM_Processor | Measure-Object -Sum -Property NumberOfLogicalProcessors).Sum
Accept pipeline input: False
Accept wildcard characters: False
```

### -Timeout
Seconds to wait without receiving any new results before giving up and stopping all remaining threads

```yaml
Type: System.Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: 120
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
Position: 12
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
Position: 13
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
