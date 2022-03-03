## Define variables

## Subscription ID array
[array]$subs = @( "subid"
)

## Define array of IP ranges for key vault service endpoint exceptions
[array]$sourceIps = @(  
    "0.0.0.0/23"
  
)

foreach ($sub in $subs) {

    $subName = (Get-AzSubscription -SubscriptionId $sub).Name
    Write-Output "Setting context to $subName"
    Set-AzContext -SubscriptionId $sub

    ## Get all Key Vaults within a subscription and export info to a csv
    $keyVaults = Get-AzKeyVault
    
    foreach ($keyVault in $keyVaults) {
    
        ## Updating the key vault IP exception list for the key vault firewall
        Update-AzKeyVaultNetworkRuleSet -VaultName $keyVault.VaultName -ResourceGroupName $keyVault.ResourceGroupName -IpAddressRange $sourceIps
        Write-Output "The IP exceptions for $($keyVault.VaultName) have been updated."


        if ($keyVault.Name -ne "" ) {

                    ## Enabling the firewall on the key vault
        Update-AzKeyVaultNetworkRuleSet -VaultName $keyVault.VaultName $keyVault.ResourceGroupName -DefaultAction Deny
        Write-Output "The firewall for $($keyVault.VaultName) has been enabled."
        }
        
        else {
            Write-Output " will not have the key vault firewall enabled."
        }
    }
}


