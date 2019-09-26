# AWS-Powershell-S3-Backup

The purpose of this project is to provide a method to upload large files to S3 for backup-purposes

# Prerequisites
Please install the AWS .Net SDK at [https://aws.amazon.com/sdk-for-net/](https://aws.amazon.com/sdk-for-net/)

You should also be running PowerShell 5+ (This may work on version 4 but is untested)

# Usage

The function needed to upload files to S3 is in "modules\s3backup\s3backup.psm1"

Load this file with `Import-Module "C:\Path\To\s3backup\s3backup.psm1"`

Exported Functions:
`Start-S3MultipartUpload`
```
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
```