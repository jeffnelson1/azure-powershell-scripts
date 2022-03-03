foreach ($server in $servers) {

Stop-Computer -ComputerName $server -Force

$azureVM = Get-AzResource -Name $server
$vmStatus = Get-AzVM -Name $azureVM.Name -ResourceGroupName $azureVM.ResourceGroupName -Status

}