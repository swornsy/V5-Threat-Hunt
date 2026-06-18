# ========================================================================
# UPDATED JITTER MODEL — RANDOM PARTITION + REMAINING TIME LOGIC
# ========================================================================

# Load config + manifest
$ConfigPath   = "C:\ProgramData\RangeEngine\Config\campaign_config.json"
$ManifestPath = "C:\ProgramData\RangeEngine\Config\campaign_manifest.json"

if (-not (Test-Path $ConfigPath) -or -not (Test-Path $ManifestPath)) {
    Write-Error "Missing critical configuration files for stager."
    exit 1
}

$Config         = Get-Content $ConfigPath -Raw | ConvertFrom-Json
$AttackSequence = Get-Content $ManifestPath -Raw | ConvertFrom-Json

$Duration       = $Config.sim_duration
$StepCount      = $AttackSequence.Count
$CampaignStart  = [int]$Config.campaign_start

# Convert duration → seconds
$TotalSeconds = switch ($Duration) {
    "test"  { 5 }
    "30m"   { 1800 }
    "24h"   { 86400 }
    "72h"   { 259200 }
    default { 1800 }
}

# Compute remaining time window
$Now = [int][DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$Elapsed = $Now - $CampaignStart
$Remaining = $TotalSeconds - $Elapsed
if ($Remaining -lt 5) { $Remaining = 5 }

# ------------------------------------------------------------------------
# RANDOM PARTITION JITTER GENERATION
# ------------------------------------------------------------------------
$JitterWindows = if ($Duration -eq "test") {
    # Provide a flat array of zero/minimal padding for test paths
    ,0 * $StepCount
} else {
    # Generate weights efficiently
    $Weights = for ($i = 0; $i -lt $StepCount; $i++) {
        Get-Random -Minimum 1 -Maximum 1000
    }
    $WeightSum = ($Weights | Measure-Object -Sum).Sum

    # Convert weights → jitter seconds
    $Windows = foreach ($w in $Weights) {
        [int](($w / $WeightSum) * $Remaining)
    }
    $Windows
}

# ------------------------------------------------------------------------
# EXECUTION LOOP
# ------------------------------------------------------------------------
for ($i = 0; $i -lt $StepCount; $i++) {
    $Step = $AttackSequence[$i]
    
    # Recalculate dynamic safety window override per loop execution
    if ($Duration -eq "test") {
        $DynamicJitter = Get-Random -Minimum 1 -Maximum 3
    } else {
        # Ensure that if prior steps ran long, we don't sleep past the remaining campaign time
        $LoopNow = [int][DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        if (($LoopNow - $CampaignStart) -ge $TotalSeconds) {
            $DynamicJitter = 0  # Campaign time exhausted, burn through remaining steps immediately
        } else {
            $DynamicJitter = $JitterWindows[$i]
        }
    }

    Start-Sleep -Seconds $DynamicJitter

    # --------------------------------------------------------------------
    # EXECUTE STEP LOGIC PRIMITIVE HERE
    # --------------------------------------------------------------------
    # Write-Output "Executing: $($Step.technique)"
}