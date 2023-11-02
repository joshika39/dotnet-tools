param(

    [string]$CustomProjectsFile = ".projects",
    [string]$EnvFile = ".env",
    [switch]$Debug
)

if (-not (Test-Path $EnvFile )) {
    Write-Output "The .env file does not exist."
    exit 1
}

get-content $EnvFile | ForEach-Object {
    $name, $value = $_.split('=')
    set-content env:\$name $value
}

if ($null -eq $env:WORK_DIR -or $null -eq $env:NUSPEC_DIR -or $null -eq $env:BUILD_CONFIG) {
    Write-Output "Missing required variables."
    exit 1
}

$nugetExePath = "$env:WORK_DIR\nuget.exe"

if ( -not (Test-Path $nugetExePath)) {
    Write-Output "Missing nuget.exe file."
    exit 1
}

if ( -not (Test-Path $env:NUSPEC_DIR\$CustomProjectsFile)) {
    Write-Output "Missing projects file."
    exit 1
}

$projects = @()
$lines = Get-Content $env:NUSPEC_DIR\$CustomProjectsFile
foreach ($line in $lines) {
    if ($line -match '^\s*#') {
        continue
    }
    $line = $line -replace '\s*#.*$'
    $parts = $line -split ':'
    
    if ($parts.Count -eq 2) {
        $project = @{
            "Name"    = $parts[0]
            "Version" = $parts[1]
        }
        $projects += $project
    }
    else {
        Write-Output "Error: Missing parameter(s) in the line: $line"
        exit
    }
}

if(-not $Debug -and -not (Test-Path $env:NUSPEC_DIR\tmp)){
    Write-Output "Created temp folder: $env:NUSPEC_DIR\tmp"
    New-Item -ItemType Directory -Path $env:NUSPEC_DIR\tmp
}

foreach ($projectData in $projects) {
    $version = $projectData["Version"]
    $versionDir = "v$version"
    $project = $projectData["Name"]

    if (-not $Debug) {
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

if(-not $Debug){
    Remove-Item -Path $env:NUSPEC_DIR\tmp\ -Recurse
}


