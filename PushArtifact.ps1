param(
    <#
    .PARAMETER WorkDir
    The file which contains the names for the nuspec files
    #>
    [string]$EnvFile = ".env",
    <#
    .PARAMETER Version
    Example: "1.0.0-pre0002" or "1.0.1" or "1.0.0-a0002" or "1.0.0-a0002"
    #>
    [Parameter(Mandatory = $true)]
    [string]$Version
)

$version = $Version
$versionDir = "v$version"

if (-not (Test-Path $EnvFile )) {
    Write-Host "The .env file does not exist."
    exit 1
}

get-content $EnvFile | ForEach-Object {
    $name, $value = $_.split('=')
    set-content env:\$name $value
}

if ($null -eq $env:WORK_DIR -or $null -eq $env:NUSPEC_DIR -or $null -eq $env:BUILD_CONFIG) {
    Write-Host "Missing required variables."
    exit 1
}

$nugetExePath = "$env:WORK_DIR\nuget.exe"

if ( -not (Test-Path $nugetExePath)) {
    Write-Host "Missing nuget.exe file."
    exit 1
}

if ( -not (Test-Path $env:NUSPEC_DIR\.projects)) {
    Write-Host "Missing projects file."
    exit 1
}

$projects = Get-Content $env:NUSPEC_DIR\.projects

foreach ($project in $projects) {
    New-Item -ItemType Directory -Path $env:NUSPEC_DIR\tmp
    Write-Host "Created temp folder: $env:NUSPEC_DIR\tmp"

    Copy-Item -Path $env:NUSPEC_DIR\Projects\$project.nuspec -Destination $env:NUSPEC_DIR\tmp
    Write-Host "Copied: $env:NUSPEC_DIR\Projects\$project.nuspec -> $env:NUSPEC_DIR\tmp\$project.nuspec"
    ((Get-Content -path $env:NUSPEC_DIR\tmp\$project.nuspec -Raw) -replace '{CONFIGURATION}', $env:BUILD_CONFIG) | Set-Content -Path $env:NUSPEC_DIR\tmp\$project.nuspec
    
    Write-Host "$project.nuspec set up with $env:BUILD_CONFIG build configuration"
    & $nugetExePath pack $env:NUSPEC_DIR\tmp\$project.nuspec -version $version -OutputDirectory $env:NUSPEC_DIR\Packages\$versionDir\
}

Remove-Item -Path $env:NUSPEC_DIR\tmp\ -Recurse


