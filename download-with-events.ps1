New-Variable -Name ZIPPYSCRAPER -Description "Zippyshare Scraper" -Option Constant -Value .\zippyshare-scraper\zippyshare.py
New-Variable -Name DOWN_JSON -Description "Download links" -Option Constant -Value .\down.json
New-Variable -Name DOWN_TEMP -Description "Temporary links" -Option Constant -Value .\temp.txt
New-Variable -Name DOWN_GENERATED -Description "Generated links" -Option Constant -Value .\links.txt
$down_file = Get-Content $DOWN_JSON | ConvertFrom-Json
$files = $down_file.Content.Package.Files
$job = $false
$action = {
    if (!$job -or $job.State -eq "Completed")
    {
        Write-Host $job
        Write-Host "Starting Download"
        if ($files)
        {
            $file_1, $file_2, $script:files = $files
            @($file_1.URL, $file_2.URL) | Out-File $DOWN_TEMP -Encoding default
            #python $ZIPPYSCRAPER --in-file $DOWN_TEMP
            Sleep -Seconds 1
            Write-Host "Downloading" $file_1.Filename "and" $file_2.Filename
            #$script:job = Start-Job -Name DownloadJob -ScriptBlock { Start-BitsTransfer (Get-Content D:\Download\links.txt) -DisplayName "Download" -Priority Normal }
            $script:job = Start-Job -Name TestJob -ScriptBlock { echo "khang" }
            Register-ObjectEvent -InputObject $job -EventName StateChanged -Action $action
        }
    }
}
try
{
    $action.Invoke()
}
finally
{
    Write-Host "Stop downling!"
    $down_file.Content.Package.Files = $files
    ConvertTo-Json $down_file -Depth 4 -Compress | Out-File $DOWN_JSON -Encoding default
    Write-Host "Done!"
}