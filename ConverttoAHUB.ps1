#############################################################################
#   Question/Comments/Concerns?                                             #
#   E-mail me @ james.hilliard@microsoft.com                                #
#   Version 1.0                                                             #
#   12/19/2018                                                              #
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

<# This PowerShell Workflow changes the LicenseType Property on Azure VM's to "Windows_Server"
   which converts the machine to leverage Azure Hybrid Use Benefits (AHUB) at
   a cost savings of about 40%. You MUST bring your own license or have an EA
   with Microsoft in order to be compliant.
#>
#Select Azure Subscription
$AvailSubscriptions = Get-AzureRmSubscription
$SelectedSubscription = $AvailSubscriptions | select Name, Id| Out-GridView -Title "Select ONE (only) Subscription" -PassThru
$SubscriptionGUID = $SelectedSubscription.Id
Select-AzureRmSubscription -Subscription $SubscriptionGUID

#Get all VM's in the selected Subscription
$VMs = Get-AzureRMVM

#Output all VM's currently not set to use AHUB
$VMs | ?{$_.LicenseType -like "Windows_Server"} | select Name

#Verifies only Windows VM's are modified since AHUB are only supported on Windows Servers
ForEach ($VM in $VMs)
{
    if ($vm.StorageProfile.OsDisk.OsType -like "Windows" -and $vm.LicenseType -like "")
    {
        Write-Output "Starting AHUB Conversion"
        $vm.LicenseType = "Windows_Server"
        Update-AzureRmVM -ResourceGroupName $vm.ResourceGroupName -VM $vm
    }
    else
    {
        Write-Output "Unable to find Windows VM's or There aren't any left to Convert"
    }
}
#Output list of machines with correct LicenseType property
$vms | ?{$_.LicenseType -like "Windows_Server"} | select ResourceGroupName, Name, LicenseType

