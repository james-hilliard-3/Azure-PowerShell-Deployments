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
#Select Subscription, gather information on all untagged resources and export to csv. Includes repeat option to run again against another subscription.

do {
  
  #Select Azure Subscription
  $AvailSubscriptions = Get-AzureRmSubscription
  $SelectedSubscription = $AvailSubscriptions | select Name, Id| Out-GridView -Title "Select ONE (only) Subscription" -PassThru
  $SubscriptionGUID = $SelectedSubscription.Id
  Select-AzureRmSubscription -Subscription $SubscriptionGUID
  $Filename = $SelectedSubscription.Name
  
  #Fetch all resource details
  $tagcount= Get-AzureRmResource | Where-Object {$PSItem.Tags.Count -eq "0"} | Export-Csv -Path "c:\scripts\$Filename.UnTagged.csv"
  $response = Read-Host "Repeat?"

  }
while ($response -eq "Y")