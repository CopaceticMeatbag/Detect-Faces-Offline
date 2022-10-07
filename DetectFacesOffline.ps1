Begin
{
    $log = "C:\Scripts\Logs\face.log"  
    $watchfolder = "c:\FTP\INCOMING"
    $errorfolder = "c:\Errored"
    $imgs = Get-ChildItem -Path $watchfolder -Filter *.jpg | select -ExpandProperty FullName
    if ($imgs.count -eq 0){exit}

    Add-Type -AssemblyName System.Runtime.WindowsRuntime
    $null = [Windows.Storage.StorageFile,                Windows.Storage,         ContentType = WindowsRuntime]
    $null = [Windows.Media.FaceAnalysis.FaceDetector,Windows.Media.FaceAnalysis,  ContentType = WindowsRuntime]
    $null = [Windows.Media.FaceAnalysis.DetectedFace,Windows.Media.FaceAnalysis,  ContentType = WindowsRuntime]
    $null = [Windows.Foundation.IAsyncOperation`1,       Windows.Foundation,      ContentType = WindowsRuntime]
    $null = [Windows.Graphics.Imaging.SoftwareBitmap,    Windows.Foundation,      ContentType = WindowsRuntime]
    $null = [Windows.Storage.Streams.RandomAccessStream, Windows.Storage.Streams, ContentType = WindowsRuntime]
    Import-Module ThreadJob
    Import-Module "C:\Scripts\UWP_Functions.psm1"
}

Process
{
    "$(get-date) - PROCESS $($imgs.Count) files" | Out-File -FilePath $log -Append
    foreach ($file in $imgs){
        Start-ThreadJob -InputObject $file -ScriptBlock {
            #Get image tags & rating
            $file = get-item -path $($input)
            $ShellApplication = New-Object -ComObject Shell.Application
            $ShellFolder = $ShellApplication.Namespace($file.directory.FullName)
            $FileInformation = Get-ItemProperty -Path $file.FullName
            $ShellFile = $ShellFolder.ParseName($FileInformation.Name)
            $Tags = (($ShellFolder.GetDetailsOf($ShellFile, 18)) -split ";").Trim()
            $Rating = ($ShellFolder.GetDetailsOf($ShellFile, 19)) -split " " | select -First 1

            "$(get-date) - DETECTING $($file.Name)" | out-file -FilePath $using:log -Append;write-host "uploading"

            $params = @{ 
                    AsyncTask  = [Windows.Media.FaceAnalysis.FaceDetector]::CreateAsync()
                    ResultType = [Windows.Media.FaceAnalysis.FaceDetector]
                }
            $facedetect = Wait-Async @params

            $params = @{ 
                AsyncTask  = [Windows.Storage.StorageFile]::GetFileFromPathAsync($file.FullName)
                ResultType = [Windows.Storage.StorageFile]
            }
            $storageFile = Wait-Async @params

            $params = @{ 
                AsyncTask  = $storageFile.OpenAsync([Windows.Storage.FileAccessMode]::Read)
                ResultType = [Windows.Storage.Streams.IRandomAccessStream]
            }
            $fileStream = Wait-Async @params

            $params = @{
                AsyncTask  = [Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($fileStream)
                ResultType = [Windows.Graphics.Imaging.BitmapDecoder]
            }
            $bitmapDecoder = Wait-Async @params

            $params = @{ 
                AsyncTask = $bitmapDecoder.GetSoftwareBitmapAsync()
                ResultType = [Windows.Graphics.Imaging.SoftwareBitmap]
            }
            $softwareBitmap = Wait-Async @params
            try{
            $finalbmp = [Windows.Graphics.Imaging.SoftwareBitmap]::Convert($softwareBitmap,[Windows.Graphics.Imaging.BitmapPixelFormat]::Gray8)
            }catch{$Error | Format-Table | out-file -FilePath $using:log -Append}

            $params = @{ 
                AsyncTask = $facedetect.DetectFacesAsync($finalbmp)
                ResultType = [System.Collections.Generic.IList[Windows.Media.FaceAnalysis.DetectedFace]]
            }
            $getfaces = Wait-Async @params
            if($getfaces){
                #don't get tiny faces    
                $faces = $getfaces | ?{$_.FaceBox.Width -gt 140}
            }
        } -InitializationScript {Import-Module "C:\Scripts\UWP_Functions.psm1"} -ThrottleLimit 6
    }
}
End
{
$runningJobs = (Get-Job | ? {($_.State -eq "Running") -or ($_.State -eq "NotStarted")}).count
While($runningJobs -ne 0){
    $runningJobs = (Get-Job | ? {($_.State -eq "Running") -or ($_.State -eq "NotStarted")}).count
}
}