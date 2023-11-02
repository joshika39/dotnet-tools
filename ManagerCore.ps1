function Get-Data {
    param(
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$LeftKey,
        [Parameter(Mandatory = $true)]
        [string]$RightKey
    )
    if ( -not (Test-Path $Path)) {
        Write-Output "Missing projects file."
        exit 1
    }

    $projects = @()
    $lines = Get-Content $Path
    foreach ($line in $lines) {
        if ($line -match '^\s*#') {
            continue
        }
        $line = $line -replace '\s*#.*$'
        $parts = $line -split ':'
        
        if ($parts.Count -eq 2) {
            $project = @{
                "$LeftKey"  = $parts[0]
                "$RightKey" = $parts[1]
            }
            $projects += $project
        }
        else {
            Write-Output "Error: Missing parameter(s) in the line: $line"
            exit
        }
    }
    return $projects
}

function Get-Environment-Variables {
    param(
        [string]$Path,
        [string[]]$RequiredVariables
    )

    if (-not (Test-Path $Path)) {
        Write-Output "The .env file does not exist."
        exit 1
    }

    $envVariables = @{}
    
    get-content $Path | ForEach-Object {
        $name, $value = $_.split('=')
        set-content env:\$name $value
        $envVariables[$name] = $value
    }

    $missingVariables = $RequiredVariables | Where-Object { $null -eq $envVariables[$_] }

    if ($missingVariables.Count -gt 0) {
        Write-Output "Missing required variables: $($missingVariables -join ', ')"
        exit 1
    }
}
