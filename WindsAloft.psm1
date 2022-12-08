$Global:WindsAloftDropZoneList = $null

function Open-WindsAloft {
    [CmdletBinding()]
    param(
        [Parameter (Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $DropZoneName
        )
    $UrlTemplate = 'https://windsaloft.us/?lat={LAT}&lon={LON}'

    $DropZoneList = Get-WindsAloftDropZoneList

    $DropZone = $DropZoneList | Where-Object { $_.DropZoneName -eq $DropZoneName }

    $Url = $UrlTemplate -replace '{LAT}', $DropZone.DropZoneLat -replace '{LON}', $DropZone.DropZoneLong

    Start-Process -FilePath $Url
}

function Get-WindsAloftDropZoneList {
    if ($null -eq $Global:WindsAloftDropZoneList) {
        $result = Invoke-RestMethod -Method Get -Uri 'https://windsaloft.us/dropzones.geojson'

        $Global:WindsAloftDropZoneList = $result.features | ForEach-Object {
            [PSCustomObject]@{
                DropZoneName = $_.properties.Name
                DropZoneLongitude = $_.geometry.coordinates[0]
                DropZoneLatitude = $_.geometry.coordinates[1]
            }
        }
    }

    Write-Output $Global:WindsAloftDropZoneList

}

function Get-WindsAloftDropZone {
    [CmdletBinding()]
    param(
        [Parameter (Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $DropZoneName
    )

    Get-WindsAloftDropZoneList | Where-Object -Property 'DropZoneName' -eq $DropZoneName
}

function Get-WindsAloftData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [PSCustomObject[]] $DropZone
    )

    begin {
        $Referer = 'SHAYDE'
    }

    process {
        foreach ($dz in $DropZone) {
            $Url = "https://windsaloft.us/winds.php?lat=$($dz.DropZoneLatitude)&lon=$($dz.DropZoneLongitude)&hourOffset=0&referrer=$Referer"

            Invoke-RestMethod -Method Get -Uri $Url
        }
    }

    end {}

}
