# Initialize the BuildHelpers environment variables here so they are usable in all child scopes including the psake properties block
BuildHelpers\Set-BuildEnvironment -Force

properties {

    # Version of the module manifest in the src directory before the build is run and the version is updated
    $SourceModuleVersion = (Import-PowerShellDataFile -Path $env:BHPSModuleManifest).ModuleVersion

    # Controls whether to "compile" module into single PSM1 or not
    $BuildCompileModule = $true

    # List of directories that if BuildCompileModule is $true, will be concatenated into the PSM1
    $BuildCompileDirectories = @('classes', 'enums', 'filters', 'functions/private', 'functions/public')

    # List of directories that will always be copied "as is" to output directory
    $BuildCopyDirectories = @('../bin', '../config', '../data', '../lib')

    # List of files (regular expressions) to exclude from output directory
    $BuildExclude = @('gitkeep', "$env:BHProjectName.psm1")

    # Output directory when building a module
    $BuildOutDir = [IO.Path]::Combine($env:BHProjectPath, 'dist')

    # Default Locale used for help generation, defaults to en-US
    # Get-UICulture doesn't return a name on Linux so default to en-US
    $HelpDefaultLocale = if (-not (Get-UICulture).Name) { 'en-US' } else { (Get-UICulture).Name }

    # Convert project readme into the module about file
    $HelpConvertReadMeToAboutHelp = $true

    # Directory PlatyPS markdown documentation will be saved to
    $DocsRootDir = [IO.Path]::Combine($env:BHProjectPath, 'docs')

    $TestRootDir = [IO.Path]::Combine($env:BHProjectPath, 'tests')
    $TestOutputFile = 'out/testResults.xml'

    # Path to updatable help CAB
    $HelpUpdatableHelpOutDir = [IO.Path]::Combine($DocsRootDir, 'UpdatableHelp')

    # Enable/disable use of PSScriptAnalyzer to perform script analysis
    $TestLintEnabled = $true

    # When PSScriptAnalyzer is enabled, control which severity level will generate a build failure.
    # Valid values are Error, Warning, Information and None.  "None" will report errors but will not
    # cause a build failure.  "Error" will fail the build only on diagnostic records that are of
    # severity error.  "Warning" will fail the build on Warning and Error diagnostic records.
    # "Any" will fail the build on any diagnostic record, regardless of severity.
    $TestLintFailBuildOnSeverityLevel = 'Error'

    # Path to the PSScriptAnalyzer settings file.
    $TestLintSettingsPath = [IO.Path]::Combine($PSScriptRoot, 'tests\ScriptAnalyzerSettings.psd1')

    $TestEnabled = $true

    $TestOutputFormat = 'NUnitXml'

    # Enable/disable Pester code coverage reporting.
    $TestCodeCoverageEnabled = $false

    # Fail Pester code coverage test if below this threshold
    $TestCodeCoverageThreshold = .75

    # CodeCoverageFiles specifies the files to perform code coverage analysis on. This property
    # acts as a direct input to the Pester -CodeCoverage parameter, so will support constructions
    # like the ones found here: https://pester.dev/docs/usage/code-coverage.
    $TestCodeCoverageFiles = @()

    # Path to write code coverage report to
    $TestCodeCoverageOutputFile = [IO.Path]::Combine($TestRootDir, 'out', 'codeCoverage.xml')

    # The code coverage output format to use
    $TestCodeCoverageOutputFileFormat = 'JaCoCo'

    $TestImportModuleFirst = $false

    # PowerShell repository name to publish modules to
    $PublishPSRepository = 'PSGallery'

    # API key to authenticate to PowerShell repository with
    $PublishPSRepositoryApiKey = $env:PSGALLERY_API_KEY

    # Credential to authenticate to PowerShell repository with
    $PublishPSRepositoryCredential = $null

    $NewLine = [System.Environment]::NewLine

}

FormatTaskName {
    param($taskName)
    Write-Host 'Task: ' -ForegroundColor Cyan -NoNewline
    Write-Host $taskName -ForegroundColor Blue
}

task Default -depends Publish

#Task Init -FromModule PowerShellBuild -minimumVersion 0.6.1

task InitializeEnvironmentVariables {

    # Should I be running Git before this? I haven't run Git yet, so BuildHelpers finds the previous commit msg and I have to use the line below to update it
    $env:BHCommitMessage = $CommitMessage

} -description 'Initialize the environment variables from the BuildHelpers module'

task UpdateModuleVersion -depends InitializeEnvironmentVariables -Action {
    $CurrentVersion = (Test-ModuleManifest $env:BHPSModuleManifest).Version
    "`tOld Version: $CurrentVersion"
    if ($IncrementMajorVersion) {
        "`tThis is a new major version"
        $NewModuleVersion = "$($CurrentVersion.Major + 1).0.0"
    } elseif ($IncrementMinorVersion) {
        "`tThis is a new minor version"
        $NewModuleVersion = "$($CurrentVersion.Major).$($CurrentVersion.Minor + 1).0"
    } else {
        "`tThis is a new build"
        $NewModuleVersion = "$($CurrentVersion.Major).$($CurrentVersion.Minor).$($CurrentVersion.Build + 1)"
    }
    "`tNew Version: $NewModuleVersion$NewLine"

    Update-Metadata -Path $env:BHPSModuleManifest -PropertyName ModuleVersion -Value $NewModuleVersion -ErrorAction Stop
} -description 'Increment the module version and update the module manifest accordingly'

task InitializePowershellBuild -depends UpdateModuleVersion {

    $NewModuleVersion = (Import-PowerShellDataFile -Path $env:BHPSModuleManifest).ModuleVersion

    if ([IO.Path]::IsPathFullyQualified($BuildOutDir)) {
        $env:BHBuildOutput = [IO.Path]::Combine(
            $BuildOutDir,
            $NewModuleVersion,
            $env:BHProjectName
        )
    } else {
        $env:BHBuildOutput = [IO.Path]::Combine(
            $env:BHProjectPath,
            $BuildOutDir,
            $NewModuleVersion,
            $env:BHProjectName
        )
    }
    <#
    $params = @{
        BuildOutput = $env:BHBuildOutput
    }
    Set-BuildEnvironment @params -Force
#>

    Write-Host "`tBuildHelpers environment variables:" -ForegroundColor Yellow
    (Get-Item ENV:BH*).Foreach({
            "`t{0,-20}{1}" -f $_.name, $_.value
        })
    $NewLine

    Write-Host "`tBuild System Details:" -ForegroundColor Yellow
    $psVersion = $PSVersionTable.PSVersion.ToString()
    $buildModuleName = $MyInvocation.MyCommand.Module.Name
    $buildModuleVersion = $MyInvocation.MyCommand.Module.Version
    "`tBuild Module:       $buildModuleName`:$buildModuleVersion"
    "`tPowerShell Version: $psVersion$NewLine"

} -description 'Initialize environment variables from the PowerShellBuild module'

task RotateBuilds -depends InitializePowershellBuild {
    $BuildVersionsToRetain = 1
    Get-ChildItem -Directory -Path $BuildOutDir |
    Sort-Object -Property Name |
    Select-Object -SkipLast ($BuildVersionsToRetain - 1) |
    ForEach-Object {
        "`tDeleting old build .\$((($_.FullName -split '\\') | Select-Object -Last 2) -join '\')"
        $_ | Remove-Item -Recurse -Force
    }
    $NewLine
} -description 'Delete all but the last 4 builds, so we will have our 5 most recent builds after the new one is complete'

task UpdateChangeLog -depends RotateBuilds -Action {
    <#
TODO
    This task runs before the Test task so that tests of the change log will pass
    But I also need one that runs *after* the build to compare it against the previous build
    The post-build UpdateChangeLog will automatically add to the change log any:
        New/removed exported commands
        New/removed files
#>
    $ChangeLog = "$env:BHProjectPath\CHANGELOG.md"
    $NewModuleVersion = (Import-PowerShellDataFile -Path $env:BHPSModuleManifest).ModuleVersion
    $NewChanges = "## [$NewModuleVersion] - $(Get-Date -format 'yyyy-MM-dd') - $CommitMessage$NewLine"
    "`tChange Log:  $ChangeLog"
    "`tNew Changes: $NewChanges"
    [string[]]$ChangeLogContents = Get-Content -Path $ChangeLog
    $LineNumberOfLastChange = Select-String -Path $ChangeLog -Pattern '^\#\# \[\d*\.\d*\.\d*\]' |
    Select-Object -First 1 -ExpandProperty LineNumber
    $HeaderLineCount = $LineNumberOfLastChange - 1
    $NewChangeLogContents = [System.Collections.Specialized.StringCollection]::new()
    $null = $NewChangeLogContents.AddRange(($ChangeLogContents |
            Select-Object -First $HeaderLineCount))
    $null = $NewChangeLogContents.Add($NewChanges)
    $null = $NewChangeLogContents.AddRange(($ChangeLogContents |
            Select-Object -Skip $HeaderLineCount))
    $NewChangeLogContents | Out-File -FilePath $ChangeLog -Encoding utf8 -Force
}

task ExportPublicFunctions -depends UpdateChangeLog -Action {
    # Discover public functions
    $ScriptFiles = Get-ChildItem -Path "$env:BHPSModulePath\*.ps1" -Recurse
    $PublicScriptFiles = $ScriptFiles | Where-Object -FilterScript {
        ($_.PSParentPath | Split-Path -Leaf) -eq 'public'
    }

    # Export public functions in the module
    $publicFunctions = $PublicScriptFiles.BaseName
    "`t$($publicFunctions -join "$NewLine`t")$NewLine"
    $PublicFunctionsJoined = $publicFunctions -join "','"
    $ModuleFilePath = "$env:BHProjectPath\src\$env:BHProjectName.psm1"
    $ModuleContent = Get-Content -Path $ModuleFilePath -Raw
    $NewFunctionExportStatement = "Export-ModuleMember -Function @('$PublicFunctionsJoined')"
    if ($ModuleContent -match 'Export-ModuleMember -Function') {
        $ModuleContent = $ModuleContent -replace 'Export-ModuleMember -Function.*' , $NewFunctionExportStatement
        $ModuleContent | Out-File -Path $ModuleFilePath -Force
    } else {
        $NewFunctionExportStatement | Out-File $ModuleFilePath -Append
    }

    # Export public functions in the manifest
    Update-MetaData -Path $env:BHPSModuleManifest -PropertyName FunctionsToExport -Value $publicFunctions

} -description 'Export all public functions in the module'

task CleanOutputDir -depends ExportPublicFunctions {
    "`tOutput: $env:BHBuildOutput"
    Clear-PSBuildOutputFolder -Path $env:BHBuildOutput
    $NewLine
} -description 'Clears module output directory'

task BuildModule -depends CleanOutputDir {
    $buildParams = @{
        Path               = $env:BHPSModulePath
        ModuleName         = $env:BHProjectName
        DestinationPath    = $env:BHBuildOutput
        Exclude            = $BuildExclude
        Compile            = $BuildCompileModule
        CompileDirectories = $BuildCompileDirectories
        CopyDirectories    = $BuildCopyDirectories
        Culture            = $HelpDefaultLocale
    }

    if ($HelpConvertReadMeToAboutHelp) {
        $readMePath = Get-ChildItem -Path $env:BHProjectPath -Include 'readme.md', 'readme.markdown', 'readme.txt' -Depth 1 |
        Select-Object -First 1
        if ($readMePath) {
            $buildParams.ReadMePath = $readMePath
        }
    }

    # only add these configuration values to the build parameters if they have been been set
    'CompileHeader', 'CompileFooter', 'CompileScriptHeader', 'CompileScriptFooter' | ForEach-Object {
        if ($PSBPreference.Build.Keys -contains $_) {
            $buildParams.$_ = $PSBPreference.Build.$_
        }
    }

    Build-PSBuildModule @buildParams
} -description 'Build a PowerShell script module based on the source directory'

$genMarkdownPreReqs = {
    $result = $true
    if (-not (Get-Module PlatyPS -ListAvailable)) {
        Write-Warning "PlatyPS module is not installed. Skipping [$($psake.context.currentTaskName)] task."
        $result = $false
    }
    $result
}

task DeleteMarkdownHelp -depends BuildModule -precondition $genMarkdownPreReqs {
    $MarkdownDir = [IO.Path]::Combine($DocsRootDir, $HelpDefaultLocale)
    "`tDeleting folder: '$MarkdownDir'"
    Get-ChildItem -Path $MarkdownDir -Recurse | Remove-Item
    $NewLine
} -description 'Delete existing .md files to prepare for PlatyPS to build new ones'

task BuildMarkdownHelp -depends DeleteMarkdownHelp {
    $ManifestPath = [IO.Path]::Combine($env:BHBuildOutput, "$env:BHProjectName.psd1")
    $moduleInfo = Import-Module $ManifestPath  -Global -Force -PassThru
    $manifestInfo = Test-ModuleManifest -Path $ManifestPath
    if ($moduleInfo.ExportedCommands.Count -eq 0) {
        Write-Warning 'No commands have been exported. Skipping markdown generation.'
        return
    }
    if (-not (Test-Path -LiteralPath $DocsRootDir)) {
        New-Item -Path $DocsRootDir -ItemType Directory > $null
    }
    try {
        if (Get-ChildItem -LiteralPath $DocsRootDir -Filter *.md -Recurse) {
            Get-ChildItem -LiteralPath $DocsRootDir -Directory | ForEach-Object {
                Update-MarkdownHelp -Path $_.FullName -Verbose:$VerbosePreference > $null
            }
        }

        $newMDParams = @{
            AlphabeticParamsOrder = $true
            Locale                = $HelpDefaultLocale
            # ErrorAction set to SilentlyContinue so this command will not overwrite an existing MD file.
            ErrorAction           = 'SilentlyContinue'
            HelpVersion           = $moduleInfo.Version
            Module                = $env:BHProjectName
            # TODO: Using GitHub pages as a container for PowerShell Updatable Help https://gist.github.com/TheFreeman193/fde11aee6998ad4c40a314667c2a3005
            # OnlineVersionUrl = $GitHubPagesLinkForThisModule
            OutputFolder          = [IO.Path]::Combine($DocsRootDir, $HelpDefaultLocale)
            UseFullTypeName       = $true
            Verbose               = $VerbosePreference
            WithModulePage        = $true
        }
        New-MarkdownHelp @newMDParams
    } finally {
        Remove-Module $env:BHProjectName -Force
    }
} -description 'Generate markdown files from the module help'

task FixMarkdownHelp -depends BuildMarkdownHelp {
    $ManifestPath = [IO.Path]::Combine($env:BHBuildOutput, "$env:BHProjectName.psd1")
    $moduleInfo = Import-Module $ManifestPath  -Global -Force -PassThru
    $manifestInfo = Test-ModuleManifest -Path $ManifestPath

    #Fix the Module Page () things PlatyPS does not do):
    $ModuleHelpFile = [IO.Path]::Combine($DocsRootDir, $HelpDefaultLocale, "$env:BHProjectName.md")
    [string]$ModuleHelp = Get-Content -LiteralPath $ModuleHelpFile -Raw

    #-Update the module description
    $RegEx = "(?ms)\#\#\ Description\s*[^\r\n]*\s*"
    $NewString = "## Description$NewLine$($moduleInfo.Description)$NewLine$NewLine"
    $ModuleHelp = $ModuleHelp -replace $RegEx, $NewString

    Write-Host "`t'`$ModuleHelp' -replace '$RegEx', '$NewString'"

    #-Update the description of each function (use its synopsis for brevity)
    ForEach ($ThisFunction in $ManifestInfo.ExportedCommands.Keys) {
        $Synopsis = (Get-Help -Name $ThisFunction).Synopsis
        $RegEx = "(?ms)\#\#\#\ \[$ThisFunction]\($ThisFunction\.md\)\s*[^\r\n]*\s*"
        $NewString = "### [$ThisFunction]($ThisFunction.md)$NewLine$Synopsis$NewLine$NewLine"
        $ModuleHelp = $ModuleHelp -replace $RegEx, $NewString
    }

    $ModuleHelp | Set-Content -LiteralPath $ModuleHelpFile -Encoding utf8
    Remove-Module $env:BHProjectName -Force
}

$genHelpFilesPreReqs = {
    $result = $true
    if (-not (Get-Module platyPS -ListAvailable)) {
        Write-Warning "platyPS module is not installed. Skipping [$($psake.context.currentTaskName)] task."
        $result = $false
    }
    $result
}

task BuildMAMLHelp -depends FixMarkdownHelp -precondition $genHelpFilesPreReqs {
    Build-PSBuildMAMLHelp -Path $DocsRootDir -DestinationPath $env:BHBuildOutput
} -description 'Generates MAML-based help from PlatyPS markdown files'

$genUpdatableHelpPreReqs = {
    $result = $true
    if (-not (Get-Module platyPS -ListAvailable)) {
        Write-Warning "platyPS module is not installed. Skipping [$($psake.context.currentTaskName)] task."
        $result = $false
    }
    $result
}

task BuildUpdatableHelp -depends BuildMAMLHelp -precondition $genUpdatableHelpPreReqs {

    $OS = (Get-CimInstance -ClassName CIM_OperatingSystem).Caption
    if ($OS -notmatch 'Windows') {
        Write-Warning 'MakeCab.exe is only available on Windows. Cannot create help cab.'
        return
    }

    $helpLocales = (Get-ChildItem -Path $DocsRootDir -Directory -Exclude 'UpdatableHelp').Name

    if ($null -eq $HelpUpdatableHelpOutDir) {
        $HelpUpdatableHelpOutDir = [IO.Path]::Combine($DocsRootDir, 'UpdatableHelp')
    }

    # Create updatable help output directory
    if (-not (Test-Path -LiteralPath $HelpUpdatableHelpOutDir)) {
        New-Item $HelpUpdatableHelpOutDir -ItemType Directory -Verbose:$VerbosePreference > $null
    } else {
        Write-Verbose "Removing existing directory: [$HelpUpdatableHelpOutDir]."
        Get-ChildItem $HelpUpdatableHelpOutDir | Remove-Item -Recurse -Force -Verbose:$VerbosePreference
    }

    # Generate updatable help files.  Note: this will currently update the version number in the module's MD
    # file in the metadata.
    foreach ($locale in $helpLocales) {
        $cabParams = @{
            CabFilesFolder  = [IO.Path]::Combine($env:BHBuildOutput, $locale)
            LandingPagePath = [IO.Path]::Combine($DocsRootDir, $locale, "$env:BHProjectName.md")
            OutputFolder    = $HelpUpdatableHelpOutDir
            Verbose         = $VerbosePreference
        }
        New-ExternalHelpCab @cabParams > $null
    }

} -description 'Create updatable help .cab file based on PlatyPS markdown help'

$analyzePreReqs = {
    $result = $true
    if (-not $TestLintEnabled) {
        Write-Warning 'Script analysis is not enabled.'
        $result = $false
    }
    if (-not (Get-Module -Name PSScriptAnalyzer -ListAvailable)) {
        Write-Warning 'PSScriptAnalyzer module is not installed'
        $result = $false
    }
    $result
}

task Lint -depends BuildUpdatableHelp -precondition $analyzePreReqs {
    $analyzeParams = @{
        Path              = $env:BHBuildOutput
        SeverityThreshold = $TestLintFailBuildOnSeverityLevel
        SettingsPath      = $TestLintSettingsPath
    }
    Test-PSBuildScriptAnalysis @analyzeParams
} -description 'Execute PSScriptAnalyzer tests'

$pesterPreReqs = {
    $result = $true
    if (-not $TestEnabled) {
        Write-Warning 'Pester testing is not enabled.'
        $result = $false
    }
    if (-not (Get-Module -Name Pester -ListAvailable)) {
        Write-Warning 'Pester module is not installed'
        $result = $false
    }
    if (-not (Test-Path -Path $TestRootDir)) {
        Write-Warning "Test directory [$TestRootDir)] not found"
        $result = $false
    }
    return $result
}

task UnitTests -depends Lint -precondition $pesterPreReqs {
    $pesterParams = @{
        Path                         = $TestRootDir
        ModuleName                   = $env:BHProjectName
        ModuleManifest               = Join-Path $env:BHBuildOutput "$env:BHProjectName.psd1"
        OutputPath                   = $TestOutputFile
        OutputFormat                 = $TestOutputFormat
        CodeCoverage                 = $TestCodeCoverageEnabled
        CodeCoverageThreshold        = $TestCodeCoverageThreshold
        CodeCoverageFiles            = $TestCodeCoverageFiles
        CodeCoverageOutputFile       = $TestCodeCoverageOutputFile
        CodeCoverageOutputFileFormat = $TestCodeCoverageOutputFormat
        ImportModule                 = $TestImportModuleFirst
    }
    Test-PSBuildPester @pesterParams
} -description 'Execute Pester tests'

task SourceControl -depends UnitTests {
    # Commit to Git
    git add .
    git commit -m $CommitMessage
    git push origin main
} -description 'git add, commit, and push'

task Publish -depends SourceControl {
    Assert -conditionToCheck ($PublishPSRepositoryApiKey -or $PublishPSRepositoryCredential) -failureMessage "API key or credential not defined to authenticate with [$PublishPSRepository)] with."

    $publishParams = @{
        Path       = $env:BHBuildOutput
        Repository = $PublishPSRepository
        Verbose    = $VerbosePreference
    }
    if ($PublishPSRepositoryApiKey) {
        $publishParams.NuGetApiKey = $PublishPSRepositoryApiKey
    }

    if ($PublishPSRepositoryCredential) {
        $publishParams.Credential = $PublishPSRepositoryCredential
    }

    # Publish to PSGallery
    #Publish-Module @publishParams
} -description 'Publish module to the defined PowerShell repository'

task FinalTasks -depends Publish {

    # Remove script-scoped variables to avoid their accidental re-use
    Remove-Variable -Name ModuleOutDir -Scope Script -Force -ErrorAction SilentlyContinue

}

task ? -description 'Lists the available tasks' {
    'Available tasks:'
    $psake.context.Peek().Tasks.Keys | Sort-Object
}


# Version of the module manifest in the src directory before the build is run and the version is updated
$SourceModuleVersion = (Import-PowerShellDataFile -Path $env:BHPSModuleManifest).ModuleVersion

# Controls whether to "compile" module into single PSM1 or not
$BuildCompileModule = $true

# List of directories that if BuildCompileModule is $true, will be concatenated into the PSM1
$BuildCompileDirectories = @('classes', 'enums', 'filters', 'functions/private', 'functions/public')

# List of directories that will always be copied "as is" to output directory
$BuildCopyDirectories = @('../bin', '../config', '../data', '../lib')

# List of files (regular expressions) to exclude from output directory
$BuildExclude = @('gitkeep', "$env:BHProjectName.psm1")

# Output directory when building a module
$BuildOutDir = [IO.Path]::Combine($env:BHProjectPath, 'dist')

# Default Locale used for help generation, defaults to en-US
# Get-UICulture doesn't return a name on Linux so default to en-US
$HelpDefaultLocale = if (-not (Get-UICulture).Name) { 'en-US' } else { (Get-UICulture).Name }

# Convert project readme into the module about file
$HelpConvertReadMeToAboutHelp = $true

# Directory PlatyPS markdown documentation will be saved to
$DocsRootDir = [IO.Path]::Combine($env:BHProjectPath, 'docs')

$TestRootDir = [IO.Path]::Combine($env:BHProjectPath, 'tests')
$TestOutputFile = 'out/testResults.xml'

# Path to updatable help CAB
$HelpUpdatableHelpOutDir = [IO.Path]::Combine($DocsRootDir, 'UpdatableHelp')

# Enable/disable use of PSScriptAnalyzer to perform script analysis
$TestLintEnabled = $true

# When PSScriptAnalyzer is enabled, control which severity level will generate a build failure.
# Valid values are Error, Warning, Information and None.  "None" will report errors but will not
# cause a build failure.  "Error" will fail the build only on diagnostic records that are of
# severity error.  "Warning" will fail the build on Warning and Error diagnostic records.
# "Any" will fail the build on any diagnostic record, regardless of severity.
$TestLintFailBuildOnSeverityLevel = 'Error'

# Path to the PSScriptAnalyzer settings file.
$TestLintSettingsPath = [IO.Path]::Combine($PSScriptRoot, 'tests\ScriptAnalyzerSettings.psd1')

$TestEnabled = $true

$TestOutputFormat = 'NUnitXml'

# Enable/disable Pester code coverage reporting.
$TestCodeCoverageEnabled = $false

# Fail Pester code coverage test if below this threshold
$TestCodeCoverageThreshold = .75

# CodeCoverageFiles specifies the files to perform code coverage analysis on. This property
# acts as a direct input to the Pester -CodeCoverage parameter, so will support constructions
# like the ones found here: https://pester.dev/docs/usage/code-coverage.
$TestCodeCoverageFiles = @()

# Path to write code coverage report to
$TestCodeCoverageOutputFile = [IO.Path]::Combine($TestRootDir, 'out', 'codeCoverage.xml')

# The code coverage output format to use
$TestCodeCoverageOutputFileFormat = 'JaCoCo'

$TestImportModuleFirst = $false

# PowerShell repository name to publish modules to
$PublishPSRepository = 'PSGallery'

# API key to authenticate to PowerShell repository with
$PublishPSRepositoryApiKey = $env:PSGALLERY_API_KEY

# Credential to authenticate to PowerShell repository with
$PublishPSRepositoryCredential = $null

$NewLine = [System.Environment]::NewLine    # Version of the module manifest in the src directory before the build is run and the version is updated
$SourceModuleVersion = (Import-PowerShellDataFile -Path $env:BHPSModuleManifest).ModuleVersion

# Controls whether to "compile" module into single PSM1 or not
$BuildCompileModule = $true

