function Get-Data {
    param(
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$LeftKey,
        [Parameter(Mandatory = $true)]
        [string]$RightKey
    )
    if ( -not (Test-Path $Path)) {
        Write-Host "Error: Missing data file."
        exit 1
    }

    $data = @()
    $lines = Get-Content $Path
    foreach ($line in $lines) {
        if ($line -match '^\s*#') {
            continue
        }
        $line = $line -replace '\s*#.*$'
        $parts = $line -split ':'
        
        if ($parts.Count -eq 2) {
            if($null -eq $parts[0] -or $null -eq $parts[1]) {
                continue
            }

            $project = @{
                "$LeftKey"  = $parts[0]
                "$RightKey" = $parts[1]
            }

            $data += $project
        }
        else {
            Write-Host "Error: Missing parameter(s) in the line: $line"
            exit
        }
    }

    if($data.Count -eq 0) {
        Write-Host "Warning: No usable data found"
        exit
    }

    Write-Host $("Discovered data count: " + $data.Count)
    Write-Host ""

    return $data
}

function Get-Environment-Variables {
    param(
        [string]$Path,
        [string[]]$RequiredVariables
    )

    if (-not (Test-Path $Path)) {
        Write-Host "The .env file does not exist."
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
        Write-Host "Missing required variables: $($missingVariables -join ', ')"
        exit 1
    }
}