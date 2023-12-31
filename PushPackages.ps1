[CmdletBinding()]
param(
    [string]$CustomProjectsFile = ".projects",
    [string]$WorkDir = ".\dotnet-tools",
    [Parameter(Mandatory=$true)]
    [string]$Source,
    [Parameter(Mandatory=$true)]
    [string]$ApiKey,
    [string]$EnvFile = ".env"
)



if ( -not (Test-Path $WorkDir\ManagerCore.ps1)) {
    Write-Host "Error: Missing Core scripts file."
    exit 1
}

. "$WorkDir\ManagerCore.ps1"

$requiredVars = @("NUSPEC_DIR")
Get-Environment-Variables -Path $EnvFile -RequiredVariables $requiredVars

foreach ($projectData in Get-Data -Path $env:NUSPEC_DIR\$CustomProjectsFile -LeftKey "Name" -RightKey "Version") {
    $version = $projectData["Version"]
    $versionDir = "v$version"
    $project = $projectData["Name"]

    if($null -eq $project -or $null -eq $versionDir -or $null -eq $version) {
        continue
    }

    if (-not $DebugPreference ) {    
        Write-Host "Info: Pushing $project to $Source"
        & dotnet nuget push .\Nuget\Packages\$project\$versionDir\*.nupkg --source $Source --api-key $ApiKey
    }
    else {
        Write-Host "(Debug) Info: Pushing $project to $Source with version $version from .\Nuget\Packages\$project\$versionDir\*.nupkg"
    }
}