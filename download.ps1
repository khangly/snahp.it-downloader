param ($downFilename = '.\down.json', $concurrentFiles = 2)

New-Variable -Name ZIPPYSCRAPER -Description "Zippyshare Scraper" -Option Constant -Value .\zippyshare-scraper\zippyshare.py
New-Variable -Name DOWN_TEMP -Description "Temporary links" -Option Constant -Value .\temp.txt
New-Variable -Name DOWN_GENERATED -Description "Generated links" -Option Constant -Value .\links.txt

$is_json = (Get-Item $downFilename).Extension -eq '.json'
if ($is_json)
{
    $down_file = Get-Content $downFilename | ConvertFrom-Json
    $files = $down_file.Content.Package.Files
}
else
{
    $files = Get-Content $downFilename
}

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
    for (; $i -lt $files.Count; $i += $concurrentFiles)
    {
        $to_download = $files[$i..($i + $concurrentFiles - 1)]
        $urls = if ($is_json) {$to_download.URL} else {$to_download}
        $urls | Out-File $DOWN_TEMP -Encoding default
        python $ZIPPYSCRAPER --in-file $DOWN_TEMP
        $display_name = if ($is_json) {$to_download[0].Filename} else {$i}
        $job = Start-BitsTransfer (Get-Content $DOWN_GENERATED) -DisplayName $display_name -Asynchronous
        Wait-BitsTransfer $job
    }
}
finally
{
    $files = $files[($i + $concurrentFiles)..($files.Count - 1)]
    if ($is_json)
    {
        $down_file.Content.Package.Files = $files
        ConvertTo-Json $down_file -Depth 4 -Compress > $downFilename
    }
    else
    {
        $files > $downFilename
    }
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