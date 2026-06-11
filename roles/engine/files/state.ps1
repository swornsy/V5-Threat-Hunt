# ========================================================================

# V5 THREAT HUNT ENGINE - LOCAL STATE MACHINE ENGINE (state.ps1)

# ========================================================================


$Global:RangeStateFile = "C:\ProgramData\RangeEngine\state.json"


function Get-RangeState {

    <#

    .SYNOPSIS

        Retrieves current campaign memory or initializes a pristine schema if missing.

    #>

    if (-not (Test-Path $Global:RangeStateFile)) {

        # Initialize an explicit ordered hash table to preserve clean JSON structure

        [ordered]@{

            owned_hosts        = @()

            discovered_hosts   = @()

            valid_credentials  = @()

            collections        = @()

            last_technique     = $null

        } | ConvertTo-Json -Depth 10 | Out-File $Global:RangeStateFile -Encoding utf8

    }


    $RawState = Get-Content $Global:RangeStateFile -Raw | ConvertFrom-Json

    

    # Critical Type-Safety Guardrail: Force properties to behave as arrays.

    # PowerShell deserializes single-item JSON arrays into primitive string objects,

    # which breaks the subsequent usage of the += operator or -notin checks.

    if ($null -eq $RawState.owned_hosts) { $RawState.owned_hosts = @() }

    else { $RawState.owned_hosts = @($RawState.owned_hosts) }


    if ($null -eq $RawState.discovered_hosts) { $RawState.discovered_hosts = @() }

    else { $RawState.discovered_hosts = @($RawState.discovered_hosts) }


    if ($null -eq $RawState.valid_credentials) { $RawState.valid_credentials = @() }

    else { $RawState.valid_credentials = @($RawState.valid_credentials) }


    if ($null -eq $RawState.collections) { $RawState.collections = @() }

    else { $RawState.collections = @($RawState.collections) }


    return $RawState

}


function Save-RangeState {

    <#

    .SYNOPSIS

        Commits active session memory modifications safely back to disk.

    #>

    param(

        [Parameter(Mandatory=$true)]

        $StateObj

    )

    $StateObj | ConvertTo-Json -Depth 10 | Out-File $Global:RangeStateFile -Encoding utf8 -Force

}


function Add-OwnedHost {

    <#

    .SYNOPSIS

        Appends a newly compromised host asset to local state memory.

    #>

    param(

        [Parameter(Mandatory=$true)]

        [string]$HostName

    )

    $state = Get-RangeState


    if ($HostName -notin $state.owned_hosts) {

        $state.owned_hosts += $HostName

        Save-RangeState $state

        Write-Output "[State Engine] Successfully registered newly owned target asset: $HostName"

    }

}


function Add-DiscoveredHost {

    <#

    .SYNOPSIS

        Appends scouted/reconnaissance network nodes to range state tracking.

    #>

    param(

        [Parameter(Mandatory=$true)]

        [string]$HostName

    )

    $state = Get-RangeState


    if ($HostName -notin $state.discovered_hosts) {

        $state.discovered_hosts += $HostName

        Save-RangeState $state

        Write-Output "[State Engine] Logged newly discovered target asset footprint: $HostName"

    }

}


function Add-Credential {

    <#

    .SYNOPSIS

        Stores harvested range credentials discovered via memory or file enumeration primitives.

    #>

    param(

        [Parameter(Mandatory=$true)]

        [string]$User,

        [Parameter(Mandatory=$true)]

        [string]$Source

    )

    $state = Get-RangeState


    # Standardize record object schema

    $CredObject = [ordered]@{

        user   = $User

        source = $Source

    }


    # Deduplicate identity credentials based on unique username entries

    $ExistingUsers = @($state.valid_credentials | ForEach-Object { $_.user })


    if ($User -notin $ExistingUsers) {

        $state.valid_credentials += $CredObject

        Save-RangeState $state

    }
