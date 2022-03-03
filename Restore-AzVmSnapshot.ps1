param (
    [Parameter(Mandatory)][string]$serverName,
    [Parameter(Mandatory)][string]$snapShotPartialName
)

$ErrorActionPreference = 'Stop'

## Set timezone to Central
Set-TimeZone -Id "Central Standard Time"

## Define variables
$vm = Get-AzVM -name $serverName
$date = get-date -f MM-dd-yyyy-hh-mmtt
$osDiskSnapshot = Get-AzSnapshot -ResourceGroupName $vm.ResourceGroupName | Where-Object -FilterScript { $_.Name -like "Snapshot-OSDisk-$snapShotPartialName" }
$dataDiskSnapshots = Get-AzSnapshot -ResourceGroupName $vm.ResourceGroupName | Where-Object -FilterScript { $_.Name -like "Snapshot-DataDisk*-$snapShotPartialName" }
$oldDataDisks = $vm.StorageProfile.DataDisks
$vmName = $vm.Name
$oldDataDiskCount = $oldDataDisks.Count

## Shutdown VM
Write-Output "Shutting down $vmName..."
$null = Stop-AzVM -Name $vmName -ResourceGroupName $vm.ResourceGroupName -Confirm:$false -Force

Write-Output "$vmName is now shutdown and deallocated..."

## Data Disks

## Check if Data Disks exist on VM
if ($null -ne $oldDataDisks) {
    Write-Output "`n$oldDataDiskCount Data Disks Found..."

    ## Compare the number of current Data Disks against the number of Data Disk snapshots.  If they don't match, terminate the script.
    if ($dataDiskSnapshots.Count -ne $oldDataDisks.Count ) {
        
        Write-Output "The number of data disks don't match the number of data disk snapshots.  Terminiating script"
        return
    }

    $i = 0
    $n = 1

    ## Loop through each Data Disk
    foreach ($oldDataDisk in $oldDataDisks) {

        ## Find the Data Disk on the VM to get the storage type
        $oldDataDiskConfig = Get-AzDisk -Name $oldDataDisks[$i].Name -ResourceGroupName $vm.ResourceGroupName
    
        ## Copy old Data Disk config
        $newDataDiskConfig = New-AzDiskConfig -AccountType $oldDataDiskConfig.sku.name -Location $oldDataDiskConfig.Location -SourceResourceId $dataDiskSnapshots[$i].Id -CreateOption Copy
        $newDataDiskName = 'DataDisk0' + $n + '-' + $vmName + '-' + $date
        $oldDataDiskName = $oldDataDisks[$i].Name

        ## Create new Data Disk
        Write-Output "`nCreating new Data Disk - $newDataDiskName..."
        $newDataDisk = New-AzDisk -Disk $newDataDiskConfig -ResourceGroupName $vm.ResourceGroupName -DiskName $newDataDiskName

        ## Detach old Data Disk
        Write-Output "Detaching old Data Disk - $oldDataDiskName..."
        $null = Remove-AzVMDataDisk -VM $vm -Name $oldDataDisks[$i].Name
        $null = Update-AzVM -ResourceGroupName $vm.ResourceGroupName -VM $vm

        ## Attach new Data Disk
        Write-Output "Attaching new Data Disk - $newDataDiskName..."
        $null = Add-AzVMDataDisk -VM $vm -Name $newDataDiskName -CreateOption Attach -ManagedDiskId $newDataDisk.Id -Lun $i
        $null = Update-AzVM -VM $vm -ResourceGroupName $vm.ResourceGroupName

        $i++
        $n++
    }

}

else {
    Write-Output "No Data Disks Found"
}

        ## OS Disk
        Write-Output "`nSwapping OS Disk..."

        ## Find the OS disk on the VM to get the storage type
        $osDiskName = $vm.StorageProfile.OsDisk.name
        $oldOsDisk = Get-AzDisk -Name $osDiskName -ResourceGroupName $vm.ResourceGroupName

        ## Copy old OS disk config
        $osDiskConfig = New-AzDiskConfig -AccountType $oldOsDisk.sku.name -Location $oldOsdisk.Location -SourceResourceId $osDiskSnapshot.Id -CreateOption Copy
        $newOsDiskName = 'OSDisk' + '-' + $vmName + '-' + $date

        ## Create new OS disk
        Write-Output "`nCreating new OS disk - $newOsDiskName..."
        $newOsDisk = New-AzDisk -Disk $osDiskConfig -ResourceGroupName $vm.ResourceGroupName -DiskName $newOsDiskName

        ## Set the VM configuration to point to the new OS disk
        $null = Set-AzVMOSDisk -VM $vm -ManagedDiskId $newOsDisk.Id -Name $newOsDisk.Name

        ## Swapping old OS disk with the new OS disk
        Write-Output "Updating VM with new OS disk..."
        $null = Update-AzVM -ResourceGroupName $vm.ResourceGroupName -VM $vm

        ## Start VM
        Write-Output "`nStarting VM - $vmName..."
        $null = Start-AzVM -Name $vmName -ResourceGroupName $vm.ResourceGroupName

        Write-Output "`n$vmName is now running..."
