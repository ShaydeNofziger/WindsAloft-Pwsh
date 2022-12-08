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

    $Url = $UrlTemplate -replace '{LAT}', $DropZone.DropZoneLatitude -replace '{LON}', $DropZone.DropZoneLongitude

    Start-Process -FilePath $Url
}

function Get-WindsAloftUriForDropZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject[]] $DropZone
    )

    begin {
        $UrlTemplate = 'https://windsaloft.us/?lat={LAT}&lon={LON}'
    }

    process {
        foreach($dz in $DropZone) {
            $Url = $UrlTemplate -replace '{LAT}', $dz.DropZoneLatitude -replace '{LON}', $dz.DropZoneLongitude

            Write-Output $Url
        }
    }

    end {}
}

function Get-WindsAloftDropZoneList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch] $Force
    )

    begin {}

    process {
        if ($Force.IsPresent -or ($null -eq $Global:WindsAloftDropZoneList)) {
            $result = Invoke-RestMethod -Method Get -Uri 'https://windsaloft.us/dropzones.geojson'
    
            $Global:WindsAloftDropZoneList = $result.features | ForEach-Object {
                [PSCustomObject]@{
                    DropZoneName = $_.properties.Name
                    DropZoneLongitude = $_.geometry.coordinates[0]
                    DropZoneLatitude = $_.geometry.coordinates[1]
                }
            } | Sort-Object -Property DropZoneName
        }
    
        Write-Output $Global:WindsAloftDropZoneList
    }

    end {}

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

function Export-WindsAloftDropZoneHtml {
    [CmdletBinding()]
    param()

    begin {}

    process {
        $AllDropZones = Get-WindsAloftDropZoneList -Force

        $HtmlString = "<html><body><h1>Winds Aloft Drop Zones</h1><ul>`r`n"
        
        foreach($dz in $AllDropZones) {
            $AnchorTagTemplate = '<li><a href="{URL}">{NAME}</a></li>'
            $AnchorTag = $AnchorTagTemplate -replace '{URL}', (Get-WindsAloftUriForDropZone -DropZone $dz) -replace '{NAME}', $dz.DropZoneName
            $HtmlString += "`r`n$AnchorTag"
        }
        
        $HtmlString += '</body></html>'
        
        $HtmlString | Out-File -FilePath "$PSScriptRoot\windsaloft.html" -Encoding utf8 -Force
    }

    end {}
}

function Export-WindsAloftDropZoneMarkdown {
    [CmdletBinding()]
    param()

    begin {}

    process {
        $AllDropZones = Get-WindsAloftDropZoneList -Force

        $MarkdownString = '# Winds Aloft Drop Zones'

        foreach($dz in $AllDropZones) {
            $AnchorTagTemplate = '-  [{NAME}]({URL})'
            $AnchorTag = $AnchorTagTemplate -replace '{URL}', (Get-WindsAloftUriForDropZone -DropZone $dz) -replace '{NAME}', $dz.DropZoneName
            $MarkdownString += "`r`n$AnchorTag"
        }

        $MarkdownString | Out-File -FilePath "$PSScriptRoot\windsaloft.md" -Encoding utf8 -Force
    }

    end {}
}
