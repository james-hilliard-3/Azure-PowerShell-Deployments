#############################################################################
#   Question/Comments/Concerns?                                             #
#   E-mail me @ james.hilliard@microsoft.com                                #
#   Version 1.0                                                             #
#   01/10/2019                                                              #
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
#This Script will swap the OSDisk of a VM to any specified disk not currently reserved.

#Enable as needed
#Login-AzureRmAccount -EnvironmentName AzureUSGovernment

#Select Azure Subscription
$AvailSubscriptions = Get-AzureRmSubscription
$SelectedSubscription = $AvailSubscriptions | select Name, Id| Out-GridView -Title "Select ONE (only) Subscription" -PassThru
$SubscriptionGUID = $SelectedSubscription.Id
Select-AzureRmSubscription -Subscription $SubscriptionGUID

$rg = "rg-name"
$vmname = "vmname"
$diskname = "diskname"

# Get the VM 
$vm = Get-AzureRmVM -ResourceGroupName $rg -Name $vmname 

# Make sure the VM is stopped\deallocated
Stop-AzureRmVM -ResourceGroupName $rg -Name $vm.Name -Force

# Get the new disk that you want to swap in
$disk = Get-AzureRmDisk -ResourceGroupName $rg -Name $diskname

# Set the VM configuration to point to the new disk  
Set-AzureRmVMOSDisk -VM $vm -ManagedDiskId $disk.Id -Name $disk.Name 

# Update the VM with the new OS disk
Update-AzureRmVM -ResourceGroupName $rg -VM $vm 

# Start the VM
Start-AzureRmVM -Name $vm.Name -ResourceGroupName $rg