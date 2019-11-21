# Nicole Welch, 10 January 2019
# James Hilliard v2.0, 21 November 2019 

# Rename existing Windows VM in Azure Portal (resource name)

# Based on https://docs.microsoft.com/en-us/azure/virtual-machines/windows/change-availability-set

Login-AzAccount -EnvironmentName AzureUSGovernment

#Select Azure Subscription
$AvailSubscriptions = Get-AzSubscription
$SelectedSubscription = $AvailSubscriptions | select Name, Id| Out-GridView -Title "Select ONE (only) Subscription" -PassThru
$SubscriptionGUID = $SelectedSubscription.Id
Select-AzSubscription -Subscription $SubscriptionGUID

#Choose Resource Group Name, set $rgName variable
$availresourcegroups = Get-AzResourceGroup
$selectedresourcegroup = $availresourcegroups | select ResourceGroupName, Location | Out-GridView -Title "Select One (only) Resource Group" -PassThru
$resourceGroup = $selectedresourcegroup.ResourceGroupName

#Text box to build $oldvmname variable
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
$vobjForm = New-Object System.Windows.Forms.Form 
$vobjForm.Text = "Enter Old VM Name"
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
$vobjLabel.Text= "Enter the old VM Name in the space below:"
$vobjForm.Controls.Add($vobjLabel)
$vobjTextBox= New-Object System.Windows.Forms.TextBox 
$vobjTextBox.Location= New-Object System.Drawing.Size(10,40)
$vobjTextBox.Size= New-Object System.Drawing.Size(260,20)
$vobjForm.Controls.Add($vobjTextBox)
$vobjForm.Topmost= $True
$vobjForm.Add_Shown({$vobjForm.Activate()})
[void]$vobjForm.ShowDialog()
$x
$oldvmName = $vobjTextBox.Text

#Text box to build $newvmname variable
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
$vobjForm = New-Object System.Windows.Forms.Form 
$vobjForm.Text = "Enter New VM Name"
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
$vobjLabel.Text= "Enter the new VM Name in the space below:"
$vobjForm.Controls.Add($vobjLabel)
$vobjTextBox= New-Object System.Windows.Forms.TextBox 
$vobjTextBox.Location= New-Object System.Drawing.Size(10,40)
$vobjTextBox.Size= New-Object System.Drawing.Size(260,20)
$vobjForm.Controls.Add($vobjTextBox)
$vobjForm.Topmost= $True
$vobjForm.Add_Shown({$vobjForm.Activate()})
[void]$vobjForm.ShowDialog()
$x
$newvmName = $vobjTextBox.Text

# Get the details of the VM to be renamed
     $originalVM = Get-AzVM `
        -ResourceGroupName $resourceGroup `
        -Name $oldvmName

# Remove the original VM
     Remove-AzVM -ResourceGroupName $resourceGroup -Name $oldvmName    

# Create the basic configuration for the replacement VM
     $newVM = New-AzRmVMConfig -VMName $newvmName -VMSize $originalVM.HardwareProfile.VmSize

    Set-AzVMOSDisk -VM $newVM -CreateOption Attach -ManagedDiskId $originalVM.StorageProfile.OsDisk.ManagedDisk.Id -Name $originalVM.StorageProfile.OsDisk.Name -Windows

# Add Data Disks
     foreach ($disk in $originalVM.StorageProfile.DataDisks) { 
     Add-AzVMDataDisk -VM $newVM `
        -Name $disk.Name `
        -ManagedDiskId $disk.ManagedDisk.Id `
        -Caching $disk.Caching `
        -Lun $disk.Lun `
        -DiskSizeInGB $disk.DiskSizeGB `
        -CreateOption Attach
     }

# Add NIC(s)
     foreach ($nic in $originalVM.NetworkProfile.NetworkInterfaces) {
         Add-AzVMNetworkInterface `
            -VM $newVM `
            -Id $nic.Id
     }

# Recreate the VM
     New-AzVM `
        -ResourceGroupName $resourceGroup `
        -Location $originalVM.Location `
        -VM $newVM `
        -DisableBginfoExtension