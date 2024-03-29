[cmdletbinding(DefaultParameterSetName = 'Task')]
param(
    # Build task(s) to execute
    [parameter(ParameterSetName = 'task', position = 0)]
    [string[]]$Task = 'default',

    [switch]$NoPublish,

    # List available build tasks
    [parameter(ParameterSetName = 'Help')]
    [switch]$Help,

    # Optional properties to pass to psake
    [hashtable]$Properties = @{},

    # Optional parameters to pass to psake
    [hashtable]$Parameters,

    # Commit message for source control
    [parameter(Mandatory)]
    [string]$CommitMessage
)

$ErrorActionPreference = 'Stop'

if (!($PSBoundParameters.ContainsKey('Parameters'))) {
    $Parameters = @{}
}
$Parameters['CommitMessage'] = $CommitMessage

if ($NoPublish) {
    $Properties['NoPublish'] = $true
}

# Execute psake task(s)
$psakeFile = './psakeFile.ps1'
if ($PSCmdlet.ParameterSetName -eq 'Help') {
    Get-PSakeScriptTasks -buildFile $psakeFile |
    Format-Table -Property Name, Description, Alias, DependsOn
} else {
    Set-BuildEnvironment -Force
    Invoke-psake -buildFile $psakeFile -taskList $Task -properties $Properties -parameters $Parameters
    exit ([int](-not $psake.build_success))
}
