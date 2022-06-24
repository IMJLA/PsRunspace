---
external help file: PsRunspace-help.xml
Module Name: PsRunspace
online version:
schema: 2.0.0
---

# Wait-Thread

## SYNOPSIS
Waits for a thread to be completed so the results can be returned, or for a timeout to be reached

## SYNTAX

```
Wait-Thread [-Thread] <PSObject[]> [[-Threads] <Int32>] [[-SleepTimer] <Int32>] [[-Timeout] <Int32>] [-Dispose]
 [<CommonParameters>]
```

## DESCRIPTION
Used by Split-Thread

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -Dispose
Dispose of the thread when it is finished

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

### -SleepTimer
Milliseconds to wait between cycles of the loop that checks threads for completion

```yaml
Type: System.Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: 200
Accept pipeline input: False
Accept wildcard characters: False
```

### -Thread
Threads to wait for

```yaml
Type: System.Management.Automation.PSObject[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Threads
Maximum number of concurrent threads that are allowed (used only for progress display)

```yaml
Type: System.Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 20
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
Position: 4
Default value: 120
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [PSCustomObject]$Thread
## OUTPUTS

### Outputs the specified output streams from the threads
## NOTES

## RELATED LINKS
