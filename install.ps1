param (
    [string]$DistroName = "AL2023",
    [ValidateSet(1, 2)]
    [int]$WslVersion = 2
)

switch ($Env:PROCESSOR_ARCHITECTURE) 
{
    "ARM64" {
        $ARCH = "arm64"
    }
    "AMD64" {
        $ARCH= "x86_64"
    }
    default {
        Write-Error "Cannot determine processor achitecture from $Env:PROCESSOR_ARCHITECTURE"
        exit 1
    }
}

wsl -d "$DistroName" -e true | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "$DistroName is already used by another install. Use a different name with param -DistroName <name>"
    exit 1
}

if (!(Test-Path -Path $Env:TEMP/AL2023.wsl)) {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Outfile $Env:TEMP/AL2023.wsl `
        -Uri https://github.com/clarson/amazon-linux-wsl/releases/latest/download/AL2023-$ARCH.wsl
}

if (!(Test-Path -Path $Env:TEMP/AL2023.wsl)) {
    Write-Host "$Env:TEMP/AL2023.wsl not found"
    exit 1
}

wsl --install --from-file $Env:TEMP/AL2023.wsl --name $DistroName --version $WslVersion
