#############################################################################
#   Question/Comments/Concerns?                                             #
#   E-mail me @ james.hilliard@microsoft.com                                #
#   Version 1.0                                                             #
#   12/14/2018                                                              #
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
# A Workflow Runbook which Shuts Down in parallel all running VM's tagged with custom tags matching the key and value outlined below, using the Run As Account (Service Principal). 

# This must run as a PowerShell Workflow Job within your Azure Automation account    

    Workflow StartupAtUTC1100
    {
     
        #If you used a custom RunAsConnection during the Automation Account setup this will need to reflect that.
       $connectionName = "AzureRunAsConnection"
        try
        {
           # Get the connection "AzureRunAsConnection "
           $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName        
            
            "Logging in to Azure..."
            Login-AzureRmAccount `
                -ServicePrincipal `
                -TenantId $servicePrincipalConnection.TenantId `
                -ApplicationId $servicePrincipalConnection.ApplicationId `
                -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint `
                -EnvironmentName AzureUSGovernment
   
        }
       catch {
           if (!$servicePrincipalConnection)
            {
               $ErrorMessage = "Connection $connectionName not found."
               throw $ErrorMessage
            }else{
               Write-Error -Message $_.Exception
               throw $_.Exception
            }
        }
       
       
       <#
        Get all VMs in the subscription with the Tag Startup:UTC1100 and Start them if they are Stopped (deallocated)
        In this section we are filtering our Get-AzureRMVM statement by selecting VM's that have a Key of Startup and Value of UTC1100, We also have implemented an If statement to only
        run against VMs that are already running.
        #>
                       
       #This is where you would set your custom Tags Keys and Values
       $VMs = Get-AzureRMVm -Status | `
       Where-Object {$PSItem.Tags.Keys -eq "Startup" -and $PSItem.Tags.Values -eq "UTC1100" `
        -and $PSItem.PowerState -eq "VM deallocated"}
       
        ForEach -Parallel ($VM in $VMs)
        {
           Write-Output "Starting: $($VM.Name)"
           Start-AzureRMVM -Name $VM.Name -ResourceGroupName $VM.ResourceGroupName
        }    
     
     }