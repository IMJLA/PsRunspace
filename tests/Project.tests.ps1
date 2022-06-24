BeforeAll {
    $moduleName = $env:BHProjectName
    $manifest = Import-PowerShellDataFile -Path $env:BHPSModuleManifest
    $outputDir = Join-Path -Path $env:BHProjectPath -ChildPath 'dist'
    $outputModVerDir = Join-Path -Path $outputDir -ChildPath $manifest.ModuleVersion
    $outputModDir = Join-Path -Path $outputModVerDir -ChildPath $env:BHProjectName
    $outputManifestPath = Join-Path -Path $outputModDir -ChildPath "$($env:BHProjectName).psd1"
    $manifestData = Test-ModuleManifest -Path $outputManifestPath -Verbose:$false -ErrorAction Stop -WarningAction SilentlyContinue

    $changelogPath = Join-Path -Path $env:BHProjectPath -Child 'CHANGELOG.md'
    Get-Content $changelogPath | ForEach-Object {
        if ($_ -match "^##\s\[(?<Version>(\d+\.){1,3}\d+)\]") {
            $changelogVersion = $matches.Version
            break
        }
    }

}

Describe "change log" {

    Context '- Version' {

        It "has a valid version" {
            $changelogVersion               | Should -Not -BeNullOrEmpty
            $changelogVersion -as [Version] | Should -Not -BeNullOrEmpty
        }

        It "has the same version as the manifest" {
            $changelogVersion -as [Version] | Should -Be ( $manifestData.Version -as [Version] )
        }

    }

}
