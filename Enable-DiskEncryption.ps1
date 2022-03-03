## Install Modules
Install-Module -Name Az.Resources -RequiredVersion 4.2.0 -Force
Install-Module -Name Az.Compute -RequiredVersion 4.15.0 -Force
Install-Module -Name Az.Network -RequiredVersion 4.10.0 -Force
Install-Module -Name Az.KeyVault -RequiredVersion 3.4.5 -Force

## Import Modules
Import-Module -Name Az.Resources
Import-Module -Name Az.Compute
Import-Module -Name Az.Network
Import-Module -Name Az.KeyVault

## Retreive Terraform Output
$vmResourceIds = terraform output vm_resource_id | ConvertFrom-Json
$primaryKeyVaultId = terraform output keyvault_resource_id | ConvertFrom-Json

## Define variables
[array]$subnetIds = $null

## Foreach loop to get the subnet IDs where the VMs reside
foreach ($vmResourceId in $vmResourceIds) {

    $server = $vmResourceId.Split("/")[-1]
    $networkInterfaceId = (Get-AzVM -Name $server).NetworkProfile.NetworkInterfaces.Id 
    $nic = Get-AzNetworkInterface -ResourceId $networkInterfaceId
    $subnetId = $nic.IpConfigurations[0].Subnet.Id

    if ($subnetIds -notcontains $subnetId) {
        $subnetIds += $subnetId

    } # end if statement

} # end foreach loop

## Foreach loop to add subnet to the Key Vault as a service endpoint
foreach ($id in $subnetIds) {

    Write-Output "Adding $id to Key Vault firewall as a service endpoint."
    Add-AzKeyVaultNetworkRule -ResourceId $primaryKeyVaultId -VirtualNetworkResourceId $id

} # end foreach loop

## Getting KeyVault objects, resource ids, and Urls
$primaryKeyVaultResource = Get-AzResource -ResourceId $primaryKeyVaultId
$primaryKeyVault = Get-AzKeyVault -ResourceGroupName $primaryKeyVaultResource.ResourceGroupName -VaultName $primaryKeyVaultResource.Name
$primaryDiskEncryptionKeyVaultUrl = $primaryKeyVault.VaultUri
$primaryKeyVaultResourceId = $primaryKeyVault.ResourceId

foreach ($vmResourceId in $vmResourceIds) {

    $vmResourceObject = Get-AzResource -ResourceId $vmResourceId
    $serverName = $vmResourceObject.Name
    $resourceGroupName = $vmResourceObject.ResourceGroupName
    $keyVaultKeyName = $vmResourceObject.Name + "-key"
    $primaryKeyEncryptionKeyUrl = (Get-AzKeyVaultKey -VaultName $primaryKeyVaultResource.Name -Name $keyVaultKeyName).Key.kid

    ## Check if the OS and data disks are encrypted
    Write-Output "Checking the encryption status on OS and Data Disks."
    $osDiskEncryptionStatus = (Get-AzVMDiskEncryptionStatus -ResourceGroupName $resourceGroupName -VMName $serverName).OsVolumeEncrypted
    $dataDisksEncryptionStatus = (Get-AzVMDiskEncryptionStatus -ResourceGroupName $resourceGroupName -VMName $serverName).DataVolumesEncrypted

    if ($osDiskEncryptionStatus -ne "Encrypted" -or $dataDisksEncryptionStatus -ne "Encrypted" ) {
        
        Write-Output "There are disks not encrypted on $serverName.  Proceeding with encryption."

        ## Using the splatting method to pass arguments to enable disk encryption
        $vmEncrpytionArguments = @{

            ResourceGroupName         = $resourceGroupName 
            VMName                    = $serverName 
            DiskEncryptionKeyVaultUrl = $primaryDiskEncryptionKeyVaultUrl
            DiskEncryptionKeyVaultId  = $primaryKeyVaultResourceId
            KeyEncryptionKeyUrl       = $primaryKeyEncryptionKeyUrl
            KeyEncryptionKeyVaultId   = $primaryKeyVaultResourceId
    
        } # end $vmEncrpytionArguments

        ## Get OS Type to see if VM is running Windows or Linux
        $osType = (Get-AzVM -Name $serverName -ResourceGroupName $resourceGroupName).StorageProfile.ImageReference.Offer
        
        ## Enabling disk encryption
        Write-Output "[Enabling encryption on $servername]"

        ## Check what version OS is running
        if ($osType -eq "WindowsServer") {

            Set-AzVMDiskEncryptionExtension @vmEncrpytionArguments -Force -Verbose
        }

        else {

            Set-AzVMDiskEncryptionExtension @vmEncrpytionArguments -skipVmBackup -VolumeType All -Force -Verbose
        }

    } # end encryption if statement

    else {
        Write-Output "All disks on $serverName are already encrypted."
    }
} # end foreach loop