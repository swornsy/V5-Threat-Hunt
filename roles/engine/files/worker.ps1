# ========================================================================

# RE-ENGINEERED PURE USER-SPACE FORENSIC COMPATIBLE WORKER (worker.ps1)

# ========================================================================

$WorkDir = "C:\ProgramData\RangeEngine"

$QueueFile = "$WorkDir\incoming.ps1"

$OutputFile = "$WorkDir\result.txt"

$StatusFile = "$WorkDir\worker.status"

$LockFile = "$WorkDir\worker.lock"


if (-not (Test-Path $WorkDir)) { New-Item -ItemType Directory -Path $WorkDir | Out-Null }

"running" | Out-File $StatusFile -Encoding ascii

$PID | Out-File $LockFile -Encoding ascii


if (Test-Path $OutputFile) { Remove-Item $OutputFile -Force }


while ($true) {

    if (Test-Path $QueueFile) {

        Start-Sleep -Milliseconds 250

        try {

            # Execute natively via script-block parsing to maintain absolute child ancestry tracking

            $ScriptBlock = [ScriptBlock]::Create((Get-Content $QueueFile -Raw))

            & $ScriptBlock > $OutputFile 2>&1

        } catch {

            $_ | Out-File $OutputFile

        }

        if (Test-Path $QueueFile) { Remove-Item $QueueFile -Force }

    }

    

    if ((Test-Path $StatusFile) -and ((Get-Content $StatusFile -Raw).Trim() -eq "terminate")) {

        Remove-Item $WorkDir -Recurse -Force -ErrorAction SilentlyContinue

        Break

    }

    Start-Sleep -Seconds 1

}
