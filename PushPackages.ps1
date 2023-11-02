[CmdletBinding()]
param(
    [string]$CustomProjectsFile = ".projects",
    [string]$WorkDir = ".\dotnet-tools",
    [Parameter(Mandatory=$true)]
    [string]$Source,
    [Parameter(Mandatory=$true)]
    [string]$ApiKey
)

if ( -not (Test-Path $WorkDir\ManagerCore.ps1)) {
    Write-Output "Missing Core scripts file."
    exit 1
}

. "$WorkDir\ManagerCore.ps1"


foreach ($projectData in Get-Data -Path $env:NUSPEC_DIR\$CustomProjectsFile -LeftKey "Name" -RightKey "Version") {
    $version = $projectData["Version"]
    $versionDir = "v$version"
    $project = $projectData["Name"]

    if (-not $DebugPreference ) {      
        & dotnet nuget push .\Nuget\Packages\$project\$versionDir\*.nupkg --source $Source --api-key $ApiKey
    }
    else {
        Write-Output "Pushing $project to $Source"
    }
}