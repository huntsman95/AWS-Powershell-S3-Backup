    Param(
    [Parameter()][string]$secondRun
    )

    if($secondRun -ne $true){
    try{
        if($cred = Get-Credential){
            Start-Process powershell.exe -Credential $cred -ArgumentList "-File .\installer.ps1 -secondRun $true"
        }
        }
        catch{Write-Host "Aborted"}
    }
    else
    {
        Write-Host -ForegroundColor Yellow "PLEASE NOTE THAT THIS INSTALLER CURRENTLY ONLY GENERATES THE SECURE CREDENTIAL FILE. YOU ARE STILL RESPONSIBLE FOR CREATING THE SCHEDULED TASK"
        $AccessKey = Read-Host "Enter Access Key"
        $SecretKey = Read-Host "Enter Secret Key"
        try{
        (New-Object -TypeName psobject -Property @{'AccessKey'=($AccessKey | ConvertTo-SecureString -AsPlainText -Force);'SecretKey'=($SecretKey | ConvertTo-SecureString -AsPlainText -Force); 'serviceAccount'=($env:USERNAME)}) | Export-Clixml $PSScriptRoot\s3credentials.xml
        Write-Host -ForegroundColor Yellow $("Wrote credential to file `"" + "$PSScriptRoot\s3credentials.xml" + "`"")
        Write-Host -ForegroundColor Yellow $("Please note that the encrypted information in this file is only readable under the current user context ($env:USERDOMAIN\$env:USERNAME)")
        }
        catch{Write-Host "ERROR"}
        Read-Host "Press Enter to Exit ..."
    }