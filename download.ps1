New-Variable -Name ZIPPYSCRAPER -Description "Zippyshare Scraper" -Option Constant -Value .\zippyshare-scraper\zippyshare.py
New-Variable -Name DOWN_JSON -Description "Download links" -Option Constant -Value .\down.json
New-Variable -Name DOWN_TEMP -Description "Temporary links" -Option Constant -Value .\temp.txt
New-Variable -Name DOWN_GENERATED -Description "Generated links" -Option Constant -Value .\links.txt
New-Variable -Name CONCURRENT_FILES -Description "Number of files to download each iteration" -Option Constant -Value 2
$down_file = Get-Content $DOWN_JSON | ConvertFrom-Json
$files = $down_file.Content.Package.Files

function Wait-BitsTransfer {
    param (
        $Job
    )
    while ($Job.JobState -ne "Transferred") {
        Start-Sleep 8
        Write-Progress -Activity "Downloading" -PercentComplete ($Job.BytesTransferred * 100 / $Job.BytesTotal)
    }
    Complete-BitsTransfer -BitsJob $Job
}

$i = 0
try
{
    for (; $i -lt $files.Count; $i += $CONCURRENT_FILES)
    {
        $to_download = $files[$i..($i + $CONCURRENT_FILES - 1)]
        $to_download.URL | Out-File $DOWN_TEMP -Encoding default
        python $ZIPPYSCRAPER --in-file $DOWN_TEMP
        $job = Start-BitsTransfer (Get-Content $DOWN_GENERATED) -DisplayName $to_download[0].Filename -Asynchronous
        Wait-BitsTransfer $job
    }
}
finally
{
    $down_file.Content.Package.Files = $files[($i + $CONCURRENT_FILES)..($files.Count - 1)]
    ConvertTo-Json $down_file -Depth 4 -Compress > $DOWN_JSON
    $shutdown = Read-Host 'Shut down after the last download? (Press "d" to sleep)'
    Wait-BitsTransfer $job
    if ($shutdown)
    {
        if ($shutdown -eq 'd')
        {
            rundll32.exe powrprof.dll,SetSuspendState
        }
        else
        {
            Stop-Computer -Force
        }
    }
}