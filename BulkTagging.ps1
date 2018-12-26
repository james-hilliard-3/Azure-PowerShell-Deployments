#############################################################################
#   Question/Comments/Concerns?                                             #
#   E-mail me @ james.hilliard@microsoft.com                                #
#   Version 1.0                                                             #
#   12/26/2018                                                              #
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
#From created reports, bulk tag VM's

#Log into Azure Government
Login-AzureRmAccount -EnvironmentName AzureUSGovernment

#Select Azure Subscription
$AvailSubscriptions = Get-AzureRmSubscription
$SelectedSubscription = $AvailSubscriptions | select Name, Id| Out-GridView -Title "Select ONE (only) Subscription" -PassThru
$SubscriptionGUID = $SelectedSubscription.Id
Select-AzureRmSubscription -Subscription $SubscriptionGUID


#Run these in order to export untagged resources, open and remove the first row
<#
$UnTaggedSA = Get-AzureRmStorageAccount | Where-Object {$PSItem.Tags.Count -eq "0"} | Export-Csv -Path "c:\scripts\sauntagged.csv"
$UnTaggedVM = Get-AzureRmVM |  Where-Object {$PSItem.Tags.Count -eq "0"} | Export-Csv -Path "c:\scripts\vmuntagged.csv"
$UnTaggedDisks = Get-AzureRmDisk |  Where-Object {$PSItem.Tags.Count -eq "0"} | Export-Csv -Path "c:\scripts\disksuntagged.csv"
$UnTaggedNICs = Get-AzureRmNetworkInterface | Where-Object {$PSItem.Tags.Count -eq "0"} | Export-Csv -Path "c:\scripts\nicsuntagged.csv"
#>

#Clear $NewTag variable and Select from existing Azure Tags
Clear-Variable -Name NewTag

$AvailTags = Get-AzureRmTag
$SelectedTag = $AvailTags | select Name, Id| Out-GridView -Title "Select ONE (only) Tag" -PassThru
$TagName = $SelectedTag.Name
$GetTagValue = Get-AzureRmTag -Name $SelectedTag.Name
$TagValue = $GetTagValue.Values.Name

#Tag variable from selected Tag
$NewTag+= @{ $TagName=$TagValue }

#Add selected Tag to the storage accounts in the csv file to be imported. CSV must have StorageAccountName and ResourceGroupName columns
<#
$SAs = Import-Csv -Path "c:\scripts\sauntagged.csv"

foreach ($SA in $SAs) {
$SAname = $SA.StorageAccountName
$SARG = $SA.ResourceGroupName
$GetSA = Get-AzureRmStorageAccount -Name $SAname -ResourceGroupName $SARG

Set-AzureRmStorageAccount -Tag $NewTag -Name $SAname -ResourceGroupName $SARG

}
#>

#Add the selected Tag to the VM's in the csv file to be imported. CSV must have Name and ResourceGroupName columns
<#
$VMs = Import-Csv -Path "c:\scripts\vmuntagged.csv"

foreach ($VM in $VMs) {
$VMname = $VM.Name
$VMRG = $VM.ResourceGroupName
$GetVM = Get-AzureRmVM -Name $VMname -ResourceGroupName $VMRG

Set-AzureRmResource -ResourceGroupName $VMRG -Name $VMname -ResourceType "Microsoft.Compute/VirtualMachines" -Tag $NewTag -Confirm:$false -Force

}
#>

#Add the selected Tag to the Network Interfaces in the csv file to be imported. CSV must have Name and ResourceGroupName columns
<#
$NICs = Import-Csv -Path "c:\scripts\nicsuntagged.csv"

foreach ($NIC in $NICs) {
$NICname = $NIC.Name
$NICRG = $NIC.ResourceGroupName
$GetNIC = Get-AzureRmNetworkInterface -Name $NICname -ResourceGroupName $NICRG
$GetNIC.Tag  += @{ $TagName=$TagValue }
Set-AzureRmNetworkInterface -NetworkInterface $GetNIC

}
#>

#Add the selected Tag to the Disks in the csv file to be imported. CSV must have Name and ResourceGroupName columns
<#
$Disks = Import-Csv -Path "c:\scripts\disksuntagged.csv"

foreach ($Disk in $Disks) {
$Diskname = $Disk.Name
$DiskRG = $Disk.ResourceGroupName
$GetDisk = Get-AzureRmDisk -Name $Diskname -ResourceGroupName $DiskRG

Set-AzureRmResource -Tag $NewTag -ResourceId $GetDisk.Id -Force

}
#>
