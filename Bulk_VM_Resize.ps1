#############################################################################
#   Question/Comments/Concerns?                                             #
#   E-mail me @ james.hilliard@microsoft.com                                # 
#                                                                           #
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
#This script will change Azure based IaaS VM Sizes to those set in the SizeMapping array
#Modify the array to change to different sizes as needed.

#Filter on VM name to restrict the list of VMs returned
$VMFilter = "*"
 
$AvailSubscriptions = Get-AzureRmSubscription
 
$ErrorActionPreference = "Stop"
$SelectedSubscription = $AvailSubscriptions | select Name, Id | Out-GridView -Title "Select ONE (only) Subscription" -PassThru
 
$SubscriptionGUID = $SelectedSubscription.Id
 
Select-AzureRmSubscription -Subscription $SubscriptionGUID
 
#Update this table if you have different mapping size requirements from old to new
$SizeMapping = @()
$SizeMapping += @{Old='Standard_DS2_v2_Promo';New='Standard_DS2_v2'}
$SizeMapping += @{Old='Standard_DS3_v2_Promo';New='Standard_DS3_v2'}
$SizeMapping += @{Old='Standard_DS4_v2_Promo';New='Standard_DS4_v2'}
$SizeMapping += @{Old='Standard_DS5_v2_Promo';New='Standard_DS5_v2'}
$SizeMapping += @{Old='Standard_DS11_v2_Promo';New='Standard_DS11_v2'}
$SizeMapping += @{Old='Standard_DS12_v2_Promo';New='Standard_DS12_v2'}
$SizeMapping += @{Old='Standard_DS13_v2_Promo';New='Standard_DS13_v2'}
$SizeMapping += @{Old='Standard_DS14_v2_Promo';New='Standard_DS14_v2'}
 
#You can use a $VMFilter, set above, to limit the script to only add filtered VM names to the array
$VMs = Get-AzureRmVM | Where-Object {$_.Name -like $VMFilter}
 
$AlteredVMs = @()
foreach ($VM in $VMs) {
    if ($VM.HardwareProfile.VmSize -in $SizeMapping.Old) {
        $Status = Get-AzureRmVM -ResourceGroupName $VM.ResourceGroupName -Name $VM.Name -Status
        $NewSize = $SizeMapping.New[$SizeMapping.Old.IndexOf($VM.HardwareProfile.VmSize)]
 
        #If the VM is running, resize it.        
        if ($Status.Statuses[1].DisplayStatus -eq "VM running") {
             
            write-output "Updating VM: $($VM.Name) from $($VM.HardwareProfile.VmSize) to $($NewSize)"
 
            $VM.HardwareProfile.VmSize = $NewSize
         
            Update-AzureRmVM -VM $VM -ResourceGroupName $VM.ResourceGroupName -Verbose
         
            $AlteredVM = new-object psobject -Property @{
                Name = $VM.Name
                ResourceGroup = $VM.ResourceGroupName
                Location = $VM.Location
                SubscriptionID = $SubscriptionGUID
                Status = $Status.Statuses[1].DisplayStatus
                VmSize = $NewSize
                
            }
            $AlteredVMs += $AlteredVM
        }
 
        #If the VM is deallocated (Powered off), resize it
        if ($Status.Statuses[1].DisplayStatus -eq "VM deallocated") {
             
            write-output "Updating Deallocated VM: $($VM.Name) from $($VM.HardwareProfile.VmSize) to $($NewSize)"
 
            $VM.HardwareProfile.VmSize = $NewSize
         
            Update-AzureRmVM -VM $VM -ResourceGroupName $VM.ResourceGroupName -Verbose
         
            $AlteredVM = new-object psobject -Property @{
                Name = $VM.Name
                ResourceGroup = $VM.ResourceGroupName
                Location = $VM.Location
                SubscriptionID = $SubscriptionGUID
                Status = $Status.Statuses[1].DisplayStatus
                VmSize = $NewSize

            }
            $AlteredVMs += $AlteredVM 
        }       
     }
 }      
 
$CurrentVMState = @()
 
foreach ($AlteredVM in $AlteredVMs) {
    $Status = Get-AzureRmVM -ResourceGroupName $AlteredVM.ResourceGroup -Name $AlteredVM.Name -Status    
    $CurrentVMState += $AlteredVM
}

$CurrentVMState | Out-GridView
