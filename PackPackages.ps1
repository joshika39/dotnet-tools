param(
    [string]$CustomProjectsFile = ".projects",
    [string]$EnvFile = ".env",
    [string]$WorkDir = ".\dotnet-tools"
)

if ( -not (Test-Path $WorkDir\ManagerCore.ps1)) {
    Write-Output "Missing Core scripts file."
    exit 1
}

$nugetExePath = "$WorkDir\nuget.exe"
if ( -not (Test-Path $nugetExePath)) {
    Write-Output "Missing nuget.exe file."
    exit 1
}


. "$WorkDir\ManagerCore.ps1"



$requiredVars = @("NUSPEC_DIR", "BUILD_CONFIG")
Get-Environment-Variables -Path $EnvFile -RequiredVariables $requiredVars


if(-not $DebugPreference -and -not (Test-Path $env:NUSPEC_DIR\tmp)){
    Write-Output "Created temp folder: $env:NUSPEC_DIR\tmp"
    New-Item -ItemType Directory -Path $env:NUSPEC_DIR\tmp
}

foreach ($projectData in Get-Data -Path $env:NUSPEC_DIR\$CustomProjectsFile -LeftKey "Name" -RightKey "Version") {
    $version = $projectData["Version"]
    $versionDir = "v$version"
    $project = $projectData["Name"]

    if (-not $DebugPreference) {
        Copy-Item -Path $env:NUSPEC_DIR\Projects\$project.nuspec -Destination $env:NUSPEC_DIR\tmp
        Write-Output "Copied: $env:NUSPEC_DIR\Projects\$project.nuspec -> $env:NUSPEC_DIR\tmp\$project.nuspec"
        ((Get-Content -path $env:NUSPEC_DIR\tmp\$project.nuspec -Raw) -replace '{CONFIGURATION}', $env:BUILD_CONFIG) | Set-Content -Path $env:NUSPEC_DIR\tmp\$project.nuspec
        Write-Output "$project.nuspec set up with $env:BUILD_CONFIG build configuration"
        
        & $nugetExePath pack $env:NUSPEC_DIR\tmp\$project.nuspec -version $version -OutputDirectory $env:NUSPEC_DIR\Packages\$project\$versionDir\
    }
    else {
        Write-Output "Created temp folder: $env:NUSPEC_DIR\tmp"
        Write-Output "Copied: $env:NUSPEC_DIR\Projects\$project.nuspec -> $env:NUSPEC_DIR\tmp\$project.nuspec"
        Write-Output "$project.nuspec set up with $env:BUILD_CONFIG build configuration"
        Write-Output "Packing $env:NUSPEC_DIR\tmp\$project.nuspec with version $version to $env:NUSPEC_DIR\Packages\$project\$versionDir\"
        Write-Output ""
    }
}

if(-not $DebugPreference){
    Remove-Item -Path $env:NUSPEC_DIR\tmp\ -Recurse
}


