function Get-NestedCommandInfo {

    <#
    .SYNOPSIS
        Return the original PsCommandInfo object as well as CommandInfo objects for any nested commands
    #>

    param (
        # CommandInfo object for the command whose nested command names to return
        [PSCustomObject]$PsCommandInfo,

        # Cache of already identified CommmandInfo objects
        [hashtable]$Cache = [hashtable]::Synchronized(@{})
    )

    # Add the first object to the cache
    $Cache[$PsCommandInfo.CommandInfo.Name] = $PsCommandInfo

    # Tokenize the function definition
    $PsTokens = $null
    $TokenizerErrors = $null
    $AbstractSyntaxTree = [System.Management.Automation.Language.Parser]::ParseInput(
        $PsCommandInfo.CommandInfo.Definition,
        [ref]$PsTokens,
        [ref]$TokenizerErrors
    )

    # Get all nested tokens
    $AllPsTokens = Expand-PsToken -InputObject $PsTokens

    # Find any other functions we also need to add
    $CommandTokens = $AllPsTokens |
    Where-Object -FilterScript {
        $_.Kind -eq 'Generic' -and
        $_.TokenFlags.HasFlag([System.Management.Automation.Language.TokenFlags]::CommandName)
    }

    # Add the definitions of those functions if available
    # TODO: Add modules if available? Not needed at this time but maybe later
    ForEach ($ThisCommandToken in $CommandTokens) {
        if (-not $Cache[$ThisCommandToken.Value] -and
            $ThisCommandToken.Value -notmatch '[\.\\]' # This excludes any file paths since they are not PowerShell commands with tokenizable definitions (they contain \ or .)
        ) {
            $TokenCommandInfo = Get-PsCommandInfo -Command $ThisCommandToken.Value
            $Cache[$ThisCommandToken.Value] = $TokenCommandInfo

            # Suppress the output of the Get-NestedCommandInfo function because we will instead be using the updated cache contents
            # This way the results are already deduplicated for us by the hashtable
            $null = Get-NestedCommandInfo -PsCommandInfo $TokenCommandInfo -Cache $Cache
        }
    }

    # Output the objects in the cache
    ForEach ($ThisKey in $Cache.Keys) {
        $Cache[$ThisKey]
    }

}
