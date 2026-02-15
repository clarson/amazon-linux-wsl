param (
    [string]$AlWslVersion = "v1.1.0",
    [string]$AlVersion = "2023.9.20250929.0",
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

if (!Test-Path -Path $Env:TEMP/$DistroName.wsl) {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Outfile $Env:TEMP/$DistroName.wsl `
        -Uri https://github.com/clarson/amazon-linux-wsl/releases/download/$AlWslVersion/$AlVersion-$ARCH.wsl
}

if (!Test-Path -Path $Env:TEMP/$DistroName.wsl) {
    Write-Host "$Env:TEMP/$DistroName.wsl not found"
    exit 1
}

wsl --install --from-file $Env:TEMP/$DistroName.wsl --name $DistroName
