#############################################################################
#   Question/Comments/Concerns?                                             #
#   E-mail me @ james.hilliard@microsoft.com                                #
#   Version 1.0                                                             #
#   09/24/2018                                                              #
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
#Converts an Azure IaaS VM from Unmanaged Disks to Managed Disks.

#Enable as needed
#Login-AzureRmAccount -EnvironmentName AzureUSGovernment

#Select Azure Subscription
$AvailSubscriptions = Get-AzureRmSubscription
$SelectedSubscription = $AvailSubscriptions | select Name, Id| Out-GridView -Title "Select ONE (only) Subscription" -PassThru
$SubscriptionGUID = $SelectedSubscription.Id
Select-AzureRmSubscription -Subscription $SubscriptionGUID

#Choose Resource Group Name, set $rgName variable
$availresourcegroups = Get-AzureRmResourceGroup
$selectedresourcegroup = $availresourcegroups | select ResourceGroupName, Location | Out-GridView -Title "Select One (only) Resource Group" -PassThru
$rgName= $selectedresourcegroup.ResourceGroupName

#Discover VM's with Unmanaged Disks, Select from the list, set the $vmName variable
$vms = Get-AzureRmVM -ResourceGroupName $rgName
$array = @()
foreach ($vm in $vms)
   {
  
   if(!$vm.StorageProfile.OsDisk.ManagedDisk){$array += $vm.Name}
   
   }

$vmselect = $array | Out-GridView -Title "Select a machine with UnManaged Disks" -PassThru
$vmName = $vmselect

#Stops VM, Converts to Managed Disks, Starts Machine
Stop-AzureRmVM -ResourceGroupName $rgName -Name $vmName -Force
ConvertTo-AzureRmVMManagedDisk -ResourceGroupName $rgName -VMName $vmName

