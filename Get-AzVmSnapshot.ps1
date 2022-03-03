param (
    [Parameter(Mandatory = $true)][string]$serverName
)

## Define variables
$vm = Get-AzVM -name $serverName

$snapShots = Get-AzSnapshot -ResourceGroupName $vm.ResourceGroupName | Where-Object -FilterScript { $_.Name -like "*$serverName*" } | Select-Object Name -ErrorAction SilentlyContinue

## Check if any snapshots exist on the VM
if ($null -ne $snapShots) {
    
    ## Get all existing VM snapshots
    Get-AzSnapshot -ResourceGroupName $vm.ResourceGroupName | Where-Object -FilterScript { $_.Name -like "*$serverName*" } | Select-Object Name

}

else {

    Write-Output "No snapshots found for $serverName..."

}



