﻿#############################################################################
#   Question/Comments/Concerns?                                             #
#   E-mail me @ james.hilliard@microsoft.com                                #
#   Version 1.0                                                             #
#   1/18/2019                                                              #
#                                                                           #
#   This Sample Code is provided for the purpose of illustration only       #
#   and is not intended to be used in a production environment.  THIS       #
#   SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT    #
#   WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT    #
#   LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS     #
#   FOR A PARTICULAR PURPOSE.  We grant You a nonexclusive, royalty-free    #
#   right to use and modify the Sample Code and to reproduce and distribute #
#   the object code form of the Sample Code, provided that You agree:       #
#   (i) to not use Our name, logo, or trademarks to market Your software    #
#   product in which the Sample Code is embedded; (ii) to include a valid   #
#   copyright notice on Your software product in which the Sample Code is   #
#   embedded; and (iii) to indemnify, hold harmless, and defend Us and      #
#   Our suppliers from and against any claims or lawsuits, including        #
#   attorneys' fees, that arise or result from the use or distribution      #
#   of the Sample Code.                                                     #
#############################################################################
#This script will import a list of VHDs, verify they are not Leased (attached to a machine), and delete them. 
#Code to generate reports is included but must be run separately.
#You must change the import/output locations within the script or create a folder named "c:\scripts" on your local machine

#Log into Azure Government
Login-AzureRmAccount -EnvironmentName AzureUSGovernment -ErrorAction Stop

#Select Azure Subscription
Function Select-Subs
{
$ErrorActionPreference = 'SilentlyContinue'
$Menu = 0
$Subs = @(Get-AzureRmSubscription | select Name,ID,TenantId)

Write-Host "Please select the subscription you want to use" -ForegroundColor Green;
$Subs |%{Write-Host "[$($Menu)]" -ForegroundColor Cyan -NoNewline ;Write-host ". $($_.Name)";$Menu++;
}
$selection = Read-Host "Please select the Subscription Number - Valid numbers are 0 - $($Subs.count -1)"
If ($Subs.item($selection) -ne $null)
{
Return @{name = $subs[$selection].Name;ID = $subs[$selection].ID}
}

}
$SubscriptionSelection = Select-Subs
Select-AzureRmSubscription -SubscriptionName $SubscriptionSelection.Name -ErrorAction Stop

#Import CSV with VHD information. Must have columns named StorageAccount, ResourceGroupName, and vhd
$VHDs = Import-Csv -Path "c:\scripts\VHDs.csv"

#Will loop through and prompt you to confirm each VHD before deleting
Foreach ($VHD in $VHDs) {

    $StorageAccount = Get-AzureRmStorageAccount -Name $VHD.StorageAccount -ResourceGroupName $VHD.ResourceGroupName
    
    $storageKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $StorageAccount.ResourceGroupName -Name $StorageAccount.StorageAccountName)[0].Value
    
    $StorageAccountContext = New-AzureStorageContext -StorageAccountName $StorageAccount.StorageAccountName -StorageAccountKey $storageKey
    
    $StorageAccountContainer = Get-AzureStorageContainer -Context $StorageAccountContext
    
    $VHDblob = Get-AzureStorageBlob -Container $StorageAccountContainer.Name -Context $StorageAccountContext -Blob $VHD.vhd

#Added an if statement as another failsafe to ensure only orphaned VHDs are targeted
if($VHDblob.ICloudBlob.Properties.LeaseStatus -eq 'Unlocked'){

            # User prompt confirmation before processing
            [string]$UserPromptMessage = "Do you want to DELETE $($VHDblob.Name) Unmanaged Disk(s)?"
            $UserPromptMessage = $UserPromptMessage + "`n`nType ""yes"" to confirm....`n`n`t"
            [string]$UserConfirmation = Read-Host -Prompt $UserPromptMessage
            if($UserConfirmation.ToLower() -ne 'yes') {

                # User reponse was NOT "yes", ake no action
                Write-Host "`nUser typed ""$($UserConfirmation)"", No deletion performed...`n`n"

            } else {
                Write-Host " "
                Write-Host "Proceeding....`n"
                Write-Host "Deleting unattached VHD with Uri: $($VHDblob.ICloudBlob.Uri.AbsoluteUri)"
                Remove-AzureStorageBlob -Container $StorageAccountContainer.Name -Context $StorageAccountContext -Blob $VHDBlob.Name -Force -PassThru
            }
     
      }

}

#Reporting script, to enable remove both <# from line 90 and #> from line 173 
<#
#Log into Azure Government
Login-AzureRmAccount -EnvironmentName AzureUSGovernment -ErrorAction Stop

#Select Azure Subscription
Function Select-Subs
{
$ErrorActionPreference = 'SilentlyContinue'
$Menu = 0
$Subs = @(Get-AzureRmSubscription | select Name,ID,TenantId)

Write-Host "Please select the subscription you want to use" -ForegroundColor Green;
$Subs |%{Write-Host "[$($Menu)]" -ForegroundColor Cyan -NoNewline ;Write-host ". $($_.Name)";$Menu++;
}
$selection = Read-Host "Please select the Subscription Number - Valid numbers are 0 - $($Subs.count -1)"
If ($Subs.item($selection) -ne $null)
{
Return @{name = $subs[$selection].Name;ID = $subs[$selection].ID}
}

}
$SubscriptionSelection = Select-Subs
Select-AzureRmSubscription -SubscriptionName $SubscriptionSelection.Name -ErrorAction Stop

Write-Host "Retrieving all VHD URI's from Storage Account" -ForegroundColor Green

$Data = @{}
$StorageAccountLoopCount = 0
$StorageAccounts = @(Get-AzureRmStorageAccount | ?{$_.StorageAccountName -notin @($ExcludedStorageAccount)})

Foreach ($StorageAccount in $StorageAccounts)
{   
    $StorageAccountLoopCount++
    $StorageAccountPercentComplete = $StorageAccountLoopCount/$StorageAccounts.Count*100    
    Write-Progress -Activity "StorageAccount Progress ($($StorageAccountLoopCount)/$($StorageAccounts.Count)):" -Status "StorageAccount: $($StorageAccount.StorageAccountName)" -PercentComplete $StorageAccountPercentComplete -Id 1

    $StorageAccountContainerLoopCount = 0
    $StorageAccountContainers = @(Get-AzureStorageContainer -Context $StorageAccount.Context )
    
       Foreach ($StorageAccountContainer in $StorageAccountContainers)
       {
            $StorageAccountContainerLoopCount++
            $StorageAccountContainerPercentComplete = $StorageAccountContainerLoopCount/$StorageAccountContainers.Count*100
            Write-Progress -Activity "StorageAccount Container Progress ($($StorageAccountContainerLoopCount)/$($StorageAccountContainers.Count)):" -Status "StorageAccount Container: $($StorageAccountContainer.Name)" -PercentComplete $StorageAccountContainerPercentComplete -Id 2 -ParentId 1

           
            Foreach ($blob in @(Get-AzureStorageBlob -Container $StorageAccountContainer.Name -Context $StorageAccount.Context -Blob "*.vhd"))
            { 
             
                IF ($blob.BlobType -eq "PageBlob")
                {
                 
                 $data."$($blob.Name)" = [PSCustomObject]@{Container = $StorageAccountContainer.Name
                                          StorageAccount = $StorageAccount.StorageAccountName
                                          ResourceGroupName = $StorageAccount.ResourceGroupName 
                                          VMName = '' 
                                          vhd = $blob.Name
                                          'Size(GB)' = [Math]::Round($blob.length /1GB,0)
                                          Sku = "[$($StorageAccount.Sku.Name)] $($StorageAccount.Sku.Tier)"
                                          LastModified = $blob.LastModified.ToString()}
                }
            }
        }
}

Write-host "Retrieving all VM's" -ForegroundColor green
$allVMS = @(Get-AzureRMVM -WarningAction SilentlyContinue )
foreach ($VM in $allVMS)
    {
    $ErrorActionPreference = 'SilentlyContinue'
    $disks = [System.Collections.ArrayList]::new() 
    $disks.add($vm.StorageProfile.OsDisk.vhd.uri.Replace('%7B','{').replace('%7D','}')) | Out-Null
    $vm.StorageProfile.DataDisks.vhd.uri | %{$disks.Add("$($_.Replace('%7B','{').replace('%7D','}'))")} | Out-Null
    $disk = [System.Collections.ArrayList]::new()
    $disks |  %{ if (($_ -Split '/')[-1] -ne ''){$Data."$(($_ -Split '/')[-1])".VMName = $VM.Name} }
    }

Write-Host "Comparing results" -ForegroundColor Green

#Change Export-Csv Path and file name if desired
($data.Keys | %{$data.$_ } | Sort-Object -Property VMName,LastModified | `
Select @{Name='VMName';E={IF ($_.VMName -eq ''){'Not Attached'}Else{$_.VMName}}},StorageAccount,ResourceGroupName,Container,vhd,Size*,Sku,LastModified |`
Export-Csv -Path "c:\scripts\orphandedvhd.csv")
#>