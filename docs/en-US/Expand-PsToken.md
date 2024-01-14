---
external help file: PsRunspace-help.xml
Module Name: PsRunspace
online version:
schema: 2.0.0
---

# Expand-PsToken

## SYNOPSIS
Recursively get nested tokens

## SYNTAX

```
Expand-PsToken [-InputObject] <PSObject> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Recursively emits all tokens embedded in a token of type "StringExpandable"
The original token is also emitted.

## EXAMPLES

### EXAMPLE 1
```
$Tokens = $null
$TokenizerErrors = $null
$AbstractSyntaxTree = [System.Management.Automation.Language.Parser]::ParseInput(
  [string]$Code,
  [ref]$Tokens,
  [ref]$TokenizerErrors
)
$Tokens |
Expand-PsToken
```

Return all tokens nested inside the provided $Code string (not scriptblock)

## PARAMETERS

### -InputObject
Management.Automation.Language.StringExpandableToken or
Management.Automation.Language.Token

```yaml
Type: System.Management.Automation.PSObject
Parameter Sets: (All)
Aliases:

Required: True
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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
