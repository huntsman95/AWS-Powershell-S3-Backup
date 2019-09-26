function Start-S3MultipartUpload()
{
<#
    .SYNOPSIS
        Uploads files to AWS S3 utilizing the AWS .Net SDK to support multipart uploads
    .PARAMETER SourceFile
        Path of the file you want to upload to S3
    .PARAMETER BucketName
        Name of the S3 bucket
    .PARAMETER Key
        Leave blank to upload the file to the root 'directory' of the bucket with its original name.
        Set this parameter in the following format to change the path/filename: path/of/directory/file.ext
    .PARAMETER Region
        Set the region your S3 bucket is in. Valid options for this script are "us-east-1","us-east-2","us-west-1","us-west-2"
    .PARAMETER AccessKey
        Set your IAM User AccessKey (Optional if SecureCredentialFile is set instead)
    .PARAMETER SecretKey
        Set your IAM User SecretKey (Optional if SecureCredentialFile is set instead)
    .PARAMETER SecureCredentialFile
        Path to the secure credential XML file created by "installer.ps1"
    .EXAMPLE
        PS> Start-S3MultipartUpload -SourceFile .\Test.zip -BucketName oh-unity-use1-backups -AccessKey "****" -SecretKey "****" -Region us-east-1
    .EXAMPLE
        PS> Start-S3MultipartUpload -SourceFile C:\SomePath\Test.zip -Key 9-15-19/Test.zip -BucketName oh-unity-use1-backups -SecureCredentialFile "C:\Path\s3credentials.xml" -Region us-east-1
#>

    param(
        [string] $SourceFile,
        [string] $BucketName,
        [string] $Key = ((Get-Item $SourceFile).Name),
        [Parameter()][ValidateSet("us-east-1","us-east-2","us-west-1","us-west-2")][string]$Region,
        [Parameter()][string]$AccessKey,
        [Parameter()][string]$SecretKey,
        [Parameter()][string]$SecureCredentialFile
        )

        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

        if($SecureCredentialFile -ne "" -and $SecureCredentialFile -ne $null){
            $credXML = Import-Clixml $SecureCredentialFile
            $AccessKey = [System.Net.NetworkCredential]::new("", ($credXML.AccessKey)).Password #decrypt AccessKey
            $SecretKey = [System.Net.NetworkCredential]::new("", ($credXML.SecretKey)).Password #decrypt SecretKey
        }

    ### LOAD RESOURCES FROM AWS SDK ###
    try{Add-Type -Path "C:\Program Files (x86)\AWS SDK for .NET\bin\Net45\AWSSDK.Core.dll"}catch{
        try{Add-Type -Path ($PSScriptRoot + "\AWSSDK.Core.dll")}
        catch{
            throw $_
        }
    }
    try{Add-Type -Path "C:\Program Files (x86)\AWS SDK for .NET\bin\Net45\AWSSDK.S3.dll"}catch{
        try{Add-Type -Path ($PSScriptRoot + "\AWSSDK.S3.dll")}
        catch{
            throw $_
        }
    }
    ### ### ###    -----    ### ### ###

    $s3Config=New-Object Amazon.S3.AmazonS3Config
    $s3Config.UseHttp = $false
    $s3Config.ServiceURL = "https://s3.$Region.amazonaws.com"
    $s3Config.BufferSize = 1024 * 32

    $client = [Amazon.S3.AmazonS3Client]::new($AccessKey,$SecretKey,$s3Config)

    $transferUtility = New-Object -TypeName Amazon.S3.Transfer.TransferUtility($client)   

    $file = Get-Item $sourceFile

    $transferUtilRequest = New-Object -TypeName Amazon.S3.Transfer.TransferUtilityUploadRequest
    $transferUtilRequest.BucketName = $bucketName
    $transferUtilRequest.FilePath = $file.FullName
    $transferUtilRequest.Key = $key
    $transferUtilRequest.AutoCloseStream = $true

    $eventsub01 = Register-ObjectEvent -InputObject $transferUtilRequest -EventName UploadProgressEvent -Action `
    {
        Write-Progress -PercentComplete ($Event.SourceEventArgs.PercentDone) -Status "Uploading" -Activity ("Uploading `"" + ($Event.SourceEventArgs.FilePath) + "`"")
        if(($Event.SourceEventArgs.PercentDone) -eq 100){
            Write-Progress -Completed -Activity ("Uploading `"" + ($Event.SourceEventArgs.FilePath) + "`"")
        }
    }

    $asyncULTASK = $transferUtility.UploadAsync($transferUtilRequest) #| Out-Null

    while(-not $asyncULTASK.AsyncWaitHandle.WaitOne(250)){}
    return (New-Object -TypeName pscustomobject -Property ([ordered]@{'FileName'=$file.FullName; "CompletedAt"=(Get-Date -UFormat "%m-%d-%y %H:%M:%S")}))
}