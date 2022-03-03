param (
    [Parameter(Mandatory = $true)][string]$serverName,
    [Parameter(Mandatory = $true)][string]$ticketNumber,
    [Parameter(Mandatory = $true)][string]$requesterName,
    [Parameter(Mandatory = $true)][string]$snapShotDescription
)

$ErrorActionPreference = 'Stop'

## Set timezone to Central
Set-TimeZone -Id "Central Standard Time"

## Define variables
$vm = Get-AzVM -Name $serverName
$resourceGroupName = $vm.ResourceGroupName
$osDiskName = $vm.StorageProfile.OsDisk.Name
$dataDisks = $vm.StorageProfile.DataDisks
$date = get-date -f MM-dd-yyyy-hh-mmtt
$snapshot = "Snapshot"
$tags = @{
    'Ticket Number'        = $ticketNumber
    'Requester'            = $requesterName
    'Snapshot Description' = $snapShotDescription
}

## Modify OS disk name
$a = $osDiskName.Split('-')
$modifiedOsDiskName = $a[0] + '-' + $a[1]

## Get OS disk config
$osDiskSnapshot = New-AzSnapshotConfig -SourceUri $vm.StorageProfile.OsDisk.ManagedDisk.Id -Location $vm.Location -CreateOption copy
$snapShotName = $snapshot + '-' + $modifiedOsDiskName + '-' + $date

## Create Snapshot for the OS Disk
Write-Output "`nCreating new OS Disk Snapshot - $snapShotName..."
$null = New-AzSnapshot -Snapshot $osDiskSnapshot -SnapshotName $snapShotName -ResourceGroupName $vm.ResourceGroupName

## Adding tags to OS disk snapshot
Write-Output "Adding tags to snapshot..."
Start-Sleep -Seconds 5
$snapShotResourceId = (Get-AzResource -Name $snapShotName -ResourceGroupName $resourceGroupName).ResourceId
$null = Set-AzResource -ResourceId $snapShotResourceId -Tags $tags -Force

## Create Snapshots for Data Disks

$i = 0
foreach ($dataDisk in $dataDisks) {
    
    $dataDiskSnapshot = New-AzSnapshotConfig -SourceUri $vm.StorageProfile.DataDisks[$i].ManagedDisk.Id -Location $vm.Location -CreateOption copy
    $dataDiskName = $vm.StorageProfile.DataDisks[$i].Name

    ## Modify data disk name
    $a = $dataDiskName.Split('-')
    $modifiedDataDiskName = $a[0] + '-' + $a[1]

    $snapShotName = $snapshot + '-' + $modifiedDataDiskName + '-' + $date

    ## Create new data disk snapshot
    Write-Output "Creating new Data Disk Snapshot - $snapShotName..."
    $null = New-AzSnapshot -Snapshot $dataDiskSnapshot -SnapshotName $snapShotName -ResourceGroupName $vm.ResourceGroupName

    ## Adding tags to the data disk snapshot
    Write-Output "Adding tags to snapshot..."
    Start-Sleep -Seconds 5
    $snapShotResourceId = (Get-AzResource -Name $snapShotName -ResourceGroupName $resourceGroupName).ResourceId
    $null = Set-AzResource -ResourceId $snapShotResourceId -Tags $tags -Force

    $i++
}