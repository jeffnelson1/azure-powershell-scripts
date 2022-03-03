param (
    [Parameter(Mandatory = $true)][string]$serverName,
    [Parameter(Mandatory = $true)][string]$snapShotPartialName
)

$ErrorActionPreference = 'Stop'

## Get snapshots for OS disk and data disks
$osDiskSnapshot = Get-AzSnapshot -ResourceGroupName $vm.ResourceGroupName | Where-Object -FilterScript { $_.Name -like "Snapshot-OSDisk-$snapShotPartialName" }
$dataDiskSnapshots = Get-AzSnapshot -ResourceGroupName $vm.ResourceGroupName | Where-Object -FilterScript { $_.Name -like "Snapshot-DataDisk*-$snapShotPartialName" }

## Define variable
$osDiskSnapshotName = $osDiskSnapshot.Name
$resourceGroupName = $osDiskSnapshot.ResourceGroupName

## Remove OS Disk snapshot
Write-Output "Removing OS disk snapshot - $osDiskSnapshotName"
Remove-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $osDiskSnapshotName -Force

## Remove Data Disk snapshots
foreach ($dataDiskSnapshot in $dataDiskSnapshots) {

    ## Define variable
    $dataDiskSnapshotName = $dataDiskSnapshot.Name
    $resourceGroupName = $dataDiskSnapshot.ResourceGroupName

    ## Remove Data Disk snapshots
    Write-Output "Removing Data Disk snapshot - $dataDiskSnapshotName"
    Remove-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $dataDiskSnapshotName -Force

}