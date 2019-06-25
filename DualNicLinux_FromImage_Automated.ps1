#############################################################################
#   Question/Comments/Concerns?                                             #
#   E-mail me @ james.hilliard@microsoft.com                                #
#   Version 1.2                                                             #
#   5/16/2019                                                               #
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
#This script will create a Linux VM from a published Managed Image and attach data disks.

Login-AzAccount -EnvironmentName AzureUSGovernment

#Select Azure Subscription
$AvailSubscriptions = Get-AzSubscription
$SelectedSubscription = $AvailSubscriptions | select Name, Id| Out-GridView -Title "Select ONE (only) Subscription" -PassThru
$SubscriptionGUID = $SelectedSubscription.Id
Select-AzSubscription -Subscription $SubscriptionGUID

#Choose Region, set $location variable
$availlocations = Get-AzLocation
$selectedlocation = $availlocations | select Location, DisplayName | Out-GridView -Title "Select One (only) Location" -PassThru
$location = $selectedlocation.Location

#Choose VMSize, set $VMSize variable
$availVMSize = Get-AzVMSize -Location $location
$SelectSize = $availVMSize | select Name, NumberOfCores, MemoryInMB, MaxDataDiskCount, OSDiskSizeInMB, ResourceDiskSizeInMB | Out-GridView -Title "Select VM Size" -PassThru
$VMSize = $SelectSize.Name

#Choose Resource Group Name, set $rgName variable
$availresourcegroups = Get-AzResourceGroup
$selectedresourcegroup = $availresourcegroups | select ResourceGroupName, Location | Out-GridView -Title "Select One (only) Resource Group" -PassThru
$rgName= $selectedresourcegroup.ResourceGroupName

#Choose Diagnostics Storage Account, set $diagstorage variable
$availdiagstorage = Get-AzStorageAccount -ResourceGroupName $rgName
$selectdiagstorage = $availdiagstorage| select StorageAccountName, Location | Out-GridView -Title "Select the Storage Account used for Boot Diag" -PassThru
$diagstorage = $selectdiagstorage.StorageAccountName

#Choose VNET, choose Subnet, set $subnetID variable for $NIC1
$availVNETs = Get-AzVirtualNetwork
$selectVNET = $availVNETs | select Name, Location, Subnets | Out-GridView -Title "Select First NIC VNET" -PassThru
$VNETSubbuild = $selectVNET.Subnets.Id | Out-GridView -Title "Select First NIC Subnet within VNET" -PassThru
$subnetID = $VNETSubbuild

#Choose VNET, choose Subnet, set $subnetID variable for $NIC2
$availVNETs2 = Get-AzVirtualNetwork
$selectVNET2 = $availVNETs2 | select Name, Location, Subnets | Out-GridView -Title "Select Second NIC VNET" -PassThru
$VNETSubbuild2 = $selectVNET2.Subnets.Id | Out-GridView -Title "Select Second NIC Subnet within VNET" -PassThru
$subnetID2 = $VNETSubbuild2

#Choose Image you would like to deploy, set $imageId variable
$availimages = Get-AzImage
$selectimage = $availimages | select Name, Location, ResourceGroupName | Out-GridView -Title "Choose the image you would like to deploy" -PassThru
$ImageNameBuild = Get-AzImage -ImageName $selectimage.Name -ResourceGroupName $selectimage.ResourceGroupName
$imageId = $ImageNameBuild.Id

#Text box to build $vmname variable
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
$vobjForm = New-Object System.Windows.Forms.Form 
$vobjForm.Text = "Enter Virtual Machine Name"
$vobjForm.Size = New-Object System.Drawing.Size(300,200)
$vobjForm.StartPosition= "CenterScreen"
$vobjForm.KeyPreview= $True
$vobjForm.Add_KeyDown({if ($_.KeyCode-eq "Enter")
    {$x=$vobjTextBox.Text;$vobjForm.Close()}})
$vobjForm.Add_KeyDown({if ($_.KeyCode-eq "Escape")
    {$vobjForm.Close()}})
$vOKButton= New-Object System.Windows.Forms.Button
$vOKButton.Location= New-Object System.Drawing.Size(75,120)
$vOKButton.Size= New-Object System.Drawing.Size(75,23)
$vOKButton.Text= "OK"
$vOKButton.Add_Click({$x=$vobjTextBox.Text;$vobjForm.Close()})
$vobjForm.Controls.Add($vOKButton)
$vCancelButton= New-Object System.Windows.Forms.Button
$vCancelButton.Location= New-Object System.Drawing.Size(150,120)
$vCancelButton.Size= New-Object System.Drawing.Size(75,23)
$vCancelButton.Text= "Cancel"
$vCancelButton.Add_Click({$vobjForm.Close()})
$vobjForm.Controls.Add($vCancelButton)
$vobjLabel= New-Object System.Windows.Forms.Label
$vobjLabel.Location= New-Object System.Drawing.Size(10,20)
$vobjLabel.Size= New-Object System.Drawing.Size(280,20)
$vobjLabel.Text= "Please enter the VM Name in the space below:"
$vobjForm.Controls.Add($vobjLabel)
$vobjTextBox= New-Object System.Windows.Forms.TextBox 
$vobjTextBox.Location= New-Object System.Drawing.Size(10,40)
$vobjTextBox.Size= New-Object System.Drawing.Size(260,20)
$vobjForm.Controls.Add($vobjTextBox)
$vobjForm.Topmost= $True
$vobjForm.Add_Shown({$vobjForm.Activate()})
[void]$vobjForm.ShowDialog()
$x
$vmname= $vobjTextBox.Text

#Text box to build $privip1 variable
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
$pip1objForm= New-Object System.Windows.Forms.Form 
$pip1objForm.Text= "Primary IP address"
$pip1objForm.Size= New-Object System.Drawing.Size(300,200)
$pip1objForm.StartPosition= "CenterScreen"
$pip1objForm.KeyPreview= $True
$pip1objForm.Add_KeyDown({if ($_.KeyCode-eq "Enter")
    {$x=$pip1objTextBox.Text;$pip1objForm.Close()}})
$pip1objForm.Add_KeyDown({if ($_.KeyCode-eq "Escape")
    {$pip1objForm.Close()}})
$pip1OKButton= New-Object System.Windows.Forms.Button
$pip1OKButton.Location= New-Object System.Drawing.Size(75,120)
$pip1OKButton.Size= New-Object System.Drawing.Size(75,23)
$pip1OKButton.Text= "OK"
$pip1OKButton.Add_Click({$x=$pip1objTextBox.Text;$pip1objForm.Close()})
$pip1objForm.Controls.Add($pip1OKButton)
$pip1CancelButton= New-Object System.Windows.Forms.Button
$pip1CancelButton.Location= New-Object System.Drawing.Size(150,120)
$pip1CancelButton.Size= New-Object System.Drawing.Size(75,23)
$pip1CancelButton.Text= "Cancel"
$pip1CancelButton.Add_Click({$pip1objForm.Close()})
$pip1objForm.Controls.Add($pip1CancelButton)
$pip1objLabel= New-Object System.Windows.Forms.Label
$pip1objLabel.Location= New-Object System.Drawing.Size(10,20)
$pip1objLabel.Size= New-Object System.Drawing.Size(280,20)
$pip1objLabel.Text= "Please enter primary static private IP below:"
$pip1objForm.Controls.Add($pip1objLabel)
$pip1objTextBox= New-Object System.Windows.Forms.TextBox 
$pip1objTextBox.Location= New-Object System.Drawing.Size(10,40)
$pip1objTextBox.Size= New-Object System.Drawing.Size(260,20)
$pip1objForm.Controls.Add($pip1objTextBox)
$pip1objForm.Topmost= $True
$pip1objForm.Add_Shown({$pip1objForm.Activate()})
[void]$pip1objForm.ShowDialog()
$x
$privip1= $pip1objTextBox.Text

#Text box to build $privip2 variable
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
$pip2objForm= New-Object System.Windows.Forms.Form 
$pip2objForm.Text= "Secondary IP address"
$pip2objForm.Size= New-Object System.Drawing.Size(300,200)
$pip2objForm.StartPosition= "CenterScreen"
$pip2objForm.KeyPreview= $True
$pip2objForm.Add_KeyDown({if ($_.KeyCode-eq "Enter")
    {$x=$pip2objTextBox.Text;$pip2objForm.Close()}})
$pip2objForm.Add_KeyDown({if ($_.KeyCode-eq "Escape")
    {$pip2objForm.Close()}})
$pip2OKButton= New-Object System.Windows.Forms.Button
$pip2OKButton.Location= New-Object System.Drawing.Size(75,120)
$pip2OKButton.Size= New-Object System.Drawing.Size(75,23)
$pip2OKButton.Text= "OK"
$pip2OKButton.Add_Click({$x=$pip2objTextBox.Text;$pip2objForm.Close()})
$pip2objForm.Controls.Add($pip2OKButton)
$pip2CancelButton= New-Object System.Windows.Forms.Button
$pip2CancelButton.Location= New-Object System.Drawing.Size(150,120)
$pip2CancelButton.Size= New-Object System.Drawing.Size(75,23)
$pip2CancelButton.Text= "Cancel"
$pip2CancelButton.Add_Click({$pip2objForm.Close()})
$pip2objForm.Controls.Add($pip2CancelButton)
$pip2objLabel= New-Object System.Windows.Forms.Label
$pip2objLabel.Location= New-Object System.Drawing.Size(10,20)
$pip2objLabel.Size= New-Object System.Drawing.Size(280,20)
$pip2objLabel.Text= "Please enter secondary static private IP below:"
$pip2objForm.Controls.Add($pip2objLabel)
$pip2objTextBox= New-Object System.Windows.Forms.TextBox 
$pip2objTextBox.Location= New-Object System.Drawing.Size(10,40)
$pip2objTextBox.Size= New-Object System.Drawing.Size(260,20)
$pip2objForm.Controls.Add($pip2objTextBox)
$pip2objForm.Topmost= $True
$pip2objForm.Add_Shown({$pip2objForm.Activate()})
[void]$pip2objForm.ShowDialog()
$x
$privip2= $pip2objTextBox.Text

#Text box to build $DataDisk1 variable
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
$dd01objForm = New-Object System.Windows.Forms.Form 
$dd01objForm.Text = "Enter DataDisk 1 Size in GB"
$dd01objForm.Size = New-Object System.Drawing.Size(300,200)
$dd01objForm.StartPosition = "CenterScreen"
$dd01objForm.KeyPreview = $True
$dd01objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter")
    {$x=$dd01objTextBox.Text;$dd01objForm.Close()}})
$dd01objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape")
    {$dd01objForm.Close()}})
$dd01OKButton = New-Object System.Windows.Forms.Button
$dd01OKButton.Location = New-Object System.Drawing.Size(75,120)
$dd01OKButton.Size = New-Object System.Drawing.Size(75,23)
$dd01OKButton.Text = "OK"
$dd01OKButton.Add_Click({$x=$dd01objTextBox.Text;$dd01objForm.Close()})
$dd01objForm.Controls.Add($dd01OKButton)
$dd01CancelButton = New-Object System.Windows.Forms.Button
$dd01CancelButton.Location = New-Object System.Drawing.Size(150,120)
$dd01CancelButton.Size = New-Object System.Drawing.Size(75,23)
$dd01CancelButton.Text = "Cancel"
$dd01CancelButton.Add_Click({$dd01objForm.Close()})
$dd01objForm.Controls.Add($dd01CancelButton)
$dd01objLabel = New-Object System.Windows.Forms.Label
$dd01objLabel.Location = New-Object System.Drawing.Size(10,20)
$dd01objLabel.Size = New-Object System.Drawing.Size(280,20)
$dd01objLabel.Text = "Please enter DataDisk 1 Size in GB below:"
$dd01objForm.Controls.Add($dd01objLabel)
$dd01objTextBox = New-Object System.Windows.Forms.TextBox 
$dd01objTextBox.Location = New-Object System.Drawing.Size(10,40)
$dd01objTextBox.Size = New-Object System.Drawing.Size(260,20)
$dd01objForm.Controls.Add($dd01objTextBox)
$dd01objForm.Topmost = $True
$dd01objForm.Add_Shown({$dd01objForm.Activate()})
[void]$dd01objForm.ShowDialog()
$x
$DataDisk1 = $dd01objTextBox.Text

#Text box to build $DataDisk2 variable
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
$dd02objForm = New-Object System.Windows.Forms.Form 
$dd02objForm.Text = "Enter DataDisk 2 Size in GB"
$dd02objForm.Size = New-Object System.Drawing.Size(300,200)
$dd02objForm.StartPosition = "CenterScreen"
$dd02objForm.KeyPreview = $True
$dd02objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter")
    {$x=$dd02objTextBox.Text;$dd02objForm.Close()}})
$dd02objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape")
    {$dd02objForm.Close()}})
$dd02OKButton = New-Object System.Windows.Forms.Button
$dd02OKButton.Location = New-Object System.Drawing.Size(75,120)
$dd02OKButton.Size = New-Object System.Drawing.Size(75,23)
$dd02OKButton.Text = "OK"
$dd02OKButton.Add_Click({$x=$dd02objTextBox.Text;$dd02objForm.Close()})
$dd02objForm.Controls.Add($dd02OKButton)
$dd02CancelButton = New-Object System.Windows.Forms.Button
$dd02CancelButton.Location = New-Object System.Drawing.Size(150,120)
$dd02CancelButton.Size = New-Object System.Drawing.Size(75,23)
$dd02CancelButton.Text = "Cancel"
$dd02CancelButton.Add_Click({$dd02objForm.Close()})
$dd02objForm.Controls.Add($dd02CancelButton)
$dd02objLabel = New-Object System.Windows.Forms.Label
$dd02objLabel.Location = New-Object System.Drawing.Size(10,20)
$dd02objLabel.Size = New-Object System.Drawing.Size(280,20)
$dd02objLabel.Text = "Please enter DataDisk 2 Size in GB below:"
$dd02objForm.Controls.Add($dd02objLabel)
$dd02objTextBox = New-Object System.Windows.Forms.TextBox 
$dd02objTextBox.Location = New-Object System.Drawing.Size(10,40)
$dd02objTextBox.Size = New-Object System.Drawing.Size(260,20)
$dd02objForm.Controls.Add($dd02objTextBox)
$dd02objForm.Topmost = $True
$dd02objForm.Add_Shown({$dd02objForm.Activate()})
[void]$dd02objForm.ShowDialog()
$x
$DataDisk2 = $dd02objTextBox.Text

#Text box to build $DataDisk3 variable
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
$dd03objForm = New-Object System.Windows.Forms.Form 
$dd03objForm.Text = "Enter DataDisk 3 Size in GB"
$dd03objForm.Size = New-Object System.Drawing.Size(300,200)
$dd03objForm.StartPosition = "CenterScreen"
$dd03objForm.KeyPreview = $True
$dd03objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter")
    {$x=$dd03objTextBox.Text;$dd03objForm.Close()}})
$dd03objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape")
    {$dd03objForm.Close()}})
$dd03OKButton = New-Object System.Windows.Forms.Button
$dd03OKButton.Location = New-Object System.Drawing.Size(75,120)
$dd03OKButton.Size = New-Object System.Drawing.Size(75,23)
$dd03OKButton.Text = "OK"
$dd03OKButton.Add_Click({$x=$dd03objTextBox.Text;$dd03objForm.Close()})
$dd03objForm.Controls.Add($dd03OKButton)
$dd03CancelButton = New-Object System.Windows.Forms.Button
$dd03CancelButton.Location = New-Object System.Drawing.Size(150,120)
$dd03CancelButton.Size = New-Object System.Drawing.Size(75,23)
$dd03CancelButton.Text = "Cancel"
$dd03CancelButton.Add_Click({$dd03objForm.Close()})
$dd03objForm.Controls.Add($dd03CancelButton)
$dd03objLabel = New-Object System.Windows.Forms.Label
$dd03objLabel.Location = New-Object System.Drawing.Size(10,20)
$dd03objLabel.Size = New-Object System.Drawing.Size(280,20)
$dd03objLabel.Text = "Please enter DataDisk 3 Size in GB below:"
$dd03objForm.Controls.Add($dd03objLabel)
$dd03objTextBox = New-Object System.Windows.Forms.TextBox 
$dd03objTextBox.Location = New-Object System.Drawing.Size(10,40)
$dd03objTextBox.Size = New-Object System.Drawing.Size(260,20)
$dd03objForm.Controls.Add($dd03objTextBox)
$dd03objForm.Topmost = $True
$dd03objForm.Add_Shown({$dd03objForm.Activate()})
[void]$dd03objForm.ShowDialog()
$x
$DataDisk3 = $dd03objTextBox.Text

#Text box to build $DataDisk4 variable
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
$dd04objForm = New-Object System.Windows.Forms.Form 
$dd04objForm.Text = "Enter DataDisk 4 Size in GB"
$dd04objForm.Size = New-Object System.Drawing.Size(300,200)
$dd04objForm.StartPosition = "CenterScreen"
$dd04objForm.KeyPreview = $True
$dd04objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter")
    {$x=$dd04objTextBox.Text;$dd04objForm.Close()}})
$dd04objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape")
    {$dd04objForm.Close()}})
$dd04OKButton = New-Object System.Windows.Forms.Button
$dd04OKButton.Location = New-Object System.Drawing.Size(75,120)
$dd04OKButton.Size = New-Object System.Drawing.Size(75,23)
$dd04OKButton.Text = "OK"
$dd04OKButton.Add_Click({$x=$dd04objTextBox.Text;$dd04objForm.Close()})
$dd04objForm.Controls.Add($dd04OKButton)
$dd04CancelButton = New-Object System.Windows.Forms.Button
$dd04CancelButton.Location = New-Object System.Drawing.Size(150,120)
$dd04CancelButton.Size = New-Object System.Drawing.Size(75,23)
$dd04CancelButton.Text = "Cancel"
$dd04CancelButton.Add_Click({$dd04objForm.Close()})
$dd04objForm.Controls.Add($dd04CancelButton)
$dd04objLabel = New-Object System.Windows.Forms.Label
$dd04objLabel.Location = New-Object System.Drawing.Size(10,20)
$dd04objLabel.Size = New-Object System.Drawing.Size(280,20)
$dd04objLabel.Text = "Please enter DataDisk 4 Size in GB below:"
$dd04objForm.Controls.Add($dd04objLabel)
$dd04objTextBox = New-Object System.Windows.Forms.TextBox 
$dd04objTextBox.Location = New-Object System.Drawing.Size(10,40)
$dd04objTextBox.Size = New-Object System.Drawing.Size(260,20)
$dd04objForm.Controls.Add($dd04objTextBox)
$dd04objForm.Topmost = $True
$dd04objForm.Add_Shown({$dd04objForm.Activate()})
[void]$dd04objForm.ShowDialog()
$x
$DataDisk4 = $dd04objTextBox.Text

#Text box to determine whether you want to Tag the resource
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
$tag1objForm= New-Object System.Windows.Forms.Form 
$tag1objForm.Text= "Add a Tag #1"
$tag1objForm.Size= New-Object System.Drawing.Size(300,200)
$tag1objForm.StartPosition= "CenterScreen"
$tag1objForm.KeyPreview= $True
$tag1objForm.Add_KeyDown({if ($_.KeyCode-eq "Enter")
    {$x=$tag1objTextBox.Text;$tag1objForm.Close()}})
$tag1objForm.Add_KeyDown({if ($_.KeyCode-eq "Escape")
    {$tag1objForm.Close()}})
$tag1OKButton= New-Object System.Windows.Forms.Button
$tag1OKButton.Location= New-Object System.Drawing.Size(75,120)
$tag1OKButton.Size= New-Object System.Drawing.Size(75,23)
$tag1OKButton.Text= "OK"
$tag1OKButton.Add_Click({$x=$tag1objTextBox.Text;$tag1objForm.Close()})
$tag1objForm.Controls.Add($tag1OKButton)
$tag1CancelButton= New-Object System.Windows.Forms.Button
$tag1CancelButton.Location= New-Object System.Drawing.Size(150,120)
$tag1CancelButton.Size= New-Object System.Drawing.Size(75,23)
$tag1CancelButton.Text= "Cancel"
$tag1CancelButton.Add_Click({$tag1objForm.Close()})
$tag1objForm.Controls.Add($tag1CancelButton)
$tag1objLabel= New-Object System.Windows.Forms.Label
$tag1objLabel.Location= New-Object System.Drawing.Size(10,20)
$tag1objLabel.Size= New-Object System.Drawing.Size(280,20)
$tag1objLabel.Text= "Please enter Yes or No Below:"
$tag1objForm.Controls.Add($tag1objLabel)
$tag1objTextBox= New-Object System.Windows.Forms.TextBox 
$tag1objTextBox.Location= New-Object System.Drawing.Size(10,40)
$tag1objTextBox.Size= New-Object System.Drawing.Size(260,20)
$tag1objForm.Controls.Add($tag1objTextBox)
$tag1objForm.Topmost= $True
$tag1objForm.Add_Shown({$tag1objForm.Activate()})
[void]$tag1objForm.ShowDialog()
$x
$tag1 = $tag1objTextBox.Text

#Gather Recovery Services Vault Information
$GetVault = Get-AzRecoveryServicesVault | select Name, resourcegroupname | Out-GridView -Title "Select the Recovery Services Vault" -PassThru | Set-AzRecoveryServicesVaultContext
$Policy = Get-AzRecoveryServicesBackupProtectionPolicy | select Name, WorkloadType | Out-GridView -Title "Select the Backup Policy" -PassThru
$PolicyGet = Get-AzRecoveryServicesBackupProtectionPolicy -Name $Policy.Name

#Variables built off of the previous data
$nic1name = "$VMname-nic"
$nic2name = "$VMname-nic2"
$osDiskName = "$VMname-OsDisk"
$DataDisk1Name = "$VMname-0"
$DataDisk2Name = "$VMname-1"
$DataDisk3Name = "$VMname-2"
$DataDisk4Name = "$VMname-3"
$imagestorage = $diagstorage

#Creates the NIC configuration
$nic1 = New-AzNetworkInterface -Name $nic1name -ResourceGroupName $rgName -Location $location -SubnetId $subnetID -PrivateIpAddress $privip1
$nic2 = New-AzNetworkInterface -Name $nic2name -ResourceGroupName $rgName -Location $location -SubnetId $subnetID2 -PrivateIpAddress $privip2

#Enter a new user name and password in the pop-up for the following (Enable on final)
$cred= Get-Credential

#Set the VM name and size
$VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $VMSize

#Add the NICs
$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC1.Id-Primary
$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC2.Id

#Set the Linux operating system configuration
$VirtualMachine = Set-AzVMBootDiagnostics -VM $VirtualMachine -Enable -ResourceGroupName $rgName -StorageAccountName $diagstorage
$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Linux -ComputerName $vmName  -Credential $cred

#Configure the OS disk to be created from image (-CreateOption fromImage) and give the URL of the captured image VHD for the -SourceImageUri parameter
Set-AzVMSourceImage -VM $VirtualMachine -Id $imageId
$VirtualMachine = Set-AzVMOSDisk -VM $VirtualMachine -Name $osDiskName -CreateOption fromImage

#Create the VM
New-AzVM -ResourceGroupName $rgName -Location $location -VM $VirtualMachine -Verbose

#----------------------------Secondary Configuration-------------------------------#

#Stop VM
Stop-AzVM -ResourceGroupName $rgName -Name $vmName -Force

#Clear $NewTag variable and Select from existing Azure Tags
Clear-Variable -Name NewTag1 -ErrorAction SilentlyContinue

$AvailTags1 = Get-AzTag
$SelectedTag1 = $AvailTags1 | select Name, Id| Out-GridView -Title "Select ONE (only) Tag" -PassThru
$TagName1 = $SelectedTag1.Name
$GetTagValue1 = Get-AzTag -Name $SelectedTag1.Name 
$TagValue1 = $GetTagValue1.Values.Name | Out-GridView -Title "Select ONE (only) Tag Value" -PassThru

#Tag variable from selected Tag
$NewTag1+= @{ $TagName1=$TagValue1 }


#Add Data Disks
$DataDiskGVM = Get-AzVM -ResourceGroupName $rgName -Name $vmname

 if($DataDisk1 -ne "") {

                Write-Host "Creating DataDisk 1"
                Add-AzVMDataDisk -VM $DataDiskGVM -Name $DataDisk1Name -Caching 'ReadOnly' -DiskSizeInGB $DataDisk1 -Lun 0 -CreateOption Empty
                Update-AzVM -ResourceGroupName $rgName -VM $DataDiskGVM
                $GetDataDisk1 = Get-AzResource -ResourceName $DataDisk1Name -ResourceGroupName $rgName
                Set-AzResource -Tag @{ $TagName1=$TagValue1 } -ResourceId $GetDataDisk1.ResourceId -Force
            } else {
                
                Write-Host "First Data Disk Not Configured"
                
            }

if($DataDisk2 -ne "") {

                Write-Host "Creating DataDisk 2"
                Add-AzVMDataDisk -VM $DataDiskGVM -Name $DataDisk2Name -Caching 'ReadOnly' -DiskSizeInGB $DataDisk2 -Lun 1 -CreateOption Empty
                Update-AzVM -ResourceGroupName $rgName -VM $DataDiskGVM
                $GetDataDisk2 = Get-AzResource -ResourceName $DataDisk2Name -ResourceGroupName $rgName
                Set-AzResource -Tag @{ $TagName1=$TagValue1 } -ResourceId $GetDataDisk2.ResourceId -Force
            } else {
                
                Write-Host "Second Data Disk Not Configured"
                
            }

if($DataDisk3 -ne "") {

                Write-Host "Creating DataDisk 3"
                Add-AzVMDataDisk -VM $DataDiskGVM -Name $DataDisk3Name -Caching 'ReadOnly' -DiskSizeInGB $DataDisk3 -Lun 2 -CreateOption Empty
                Update-AzVM -ResourceGroupName $rgName -VM $DataDiskGVM
                $GetDataDisk3 = Get-AzResource -ResourceName $DataDisk3Name -ResourceGroupName $rgName
                Set-AzResource -Tag @{ $TagName1=$TagValue1 } -ResourceId $GetDataDisk3.ResourceId -Force
            } else {
                
                Write-Host "Third Data Disk Not Configured"
                
            }

if($DataDisk4 -ne "") {

                Write-Host "Creating DataDisk 4"
                Add-AzVMDataDisk -VM $DataDiskGVM -Name $DataDisk4Name -Caching 'ReadOnly' -DiskSizeInGB $DataDisk4 -Lun 3 -CreateOption Empty
                Update-AzVM -ResourceGroupName $rgName -VM $DataDiskGVM
                $GetDataDisk4 = Get-AzResource -ResourceName $DataDisk4Name -ResourceGroupName $rgName
                Set-AzResource -Tag @{ $TagName1=$TagValue1 } -ResourceId $GetDataDisk4.ResourceId -Force
            } else {
                
                Write-Host "Fourth Data Disk Not Configured"
                
            }

if($tag1 -eq "yes") {

                #Tag VM
                Set-AzResource -ResourceGroupName $rgName -Name $vmName -ResourceType "Microsoft.Compute/VirtualMachines" -Tag $NewTag1 -Confirm:$false -Force
                                
                #Tag NIC1
                $GetNIC1 = Get-AzNetworkInterface -Name $nic1name -ResourceGroupName $rgName
                $GetNIC1.Tag  += @{ $TagName1=$TagValue1 }
                Set-AzNetworkInterface -NetworkInterface $GetNIC1

                #Tag NIC2
                $GetNIC2 = Get-AzNetworkInterface -Name $nic2name -ResourceGroupName $rgName
                $GetNIC2.Tag  += @{ $TagName1=$TagValue1 }
                Set-AzNetworkInterface -NetworkInterface $GetNIC2

                #Tag OSDisk
                $GetOSDisk = Get-AzResource -ResourceName $osDiskName -ResourceGroupName $rgName
                Set-AzResource -Tag @{ $TagName1=$TagValue1 } -ResourceId $GetOSDisk.ResourceId -Force                

            } else {
                
                Write-Host "First Tag Not Selected"
                
            }

#Enable Backup Protection Policy
Enable-AzRecoveryServicesBackupProtection -ResourceGroupName $rgName -Name $vmName -Policy $PolicyGet

#Assign RBAC Role
$RBACID = Get-AzVM -ResourceGroupName $rgName -Name $vmname
$RBACGroup = Get-AzADGroup -SearchString Azure-TFS | select DisplayName, Id, Type | Out-GridView -Title "Select the Azure TFS Group" -PassThru
$RBACRole = Get-AzRoleDefinition | select Name, Description, Id | Out-GridView -Title "Select the Role" -PassThru
New-AzRoleAssignment -ObjectID $RBACGroup.Id -RoleDefinitionName $RBACRole.Name -Scope $RBACID.Id

#Start VM
Start-AzVM -ResourceGroupName $rgName -Name $vmName

#Output variables in case you need to rebuild the machine later
$VMname,$VMSize,$rgName,$selectedSA.StorageAccountName,$Location,$osDiskName,$osDiskVhdUri,$DataDisk1Name,$DataDisk2Name,$DataDisk3Name,$DataDisk4Name,$privip1,$privip2 | Out-File "\\orgeast\DLA_SOFTWARE\DAY\public\Azure Transfers\ToolsServerTransfer\scripts\$VMname.txt"
