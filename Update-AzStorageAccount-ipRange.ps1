function Update-AzStorageAccount-ipRange {
    [cmdletbinding()]
    ## Define parameters
    Param (
        [string]$ipRanges
    )

    $subs = @( "subid"
    )
    
    foreach ($sub in $subs) {

        $subName = (Get-AzSubscription -SubscriptionId $sub).Name
        Write-Output "Setting context to $subName"
        Set-AzContext -SubscriptionId $sub

        ## Get all Storage Accounts within a subscription
        $storageAccounts = Get-AzStorageAccount

        Write-Output "Starting Storage Accounts"

        foreach ($storageAccount in $storageAccounts) {

            $networkRuleStatus = $storageAccount.NetworkRuleSet.DefaultAction

            if ($networkRuleStatus -ne "Allow") {
            
                Write-Output "Adding IP ranges to $($storageAccount.StorageAccountName)."
                Add-AzStorageAccountNetworkRule -ResourceGroupName $storageAccount.ResourceGroupName -Name $storageAccount.StorageAccountName -IPAddressOrRange $ipRanges
                Write-Output "$($storageAccount.StorageAccountName) is complete."
            }

            else {
                Write-Output "The Network Ruleset is set to Allowed on $($storageAccount.StorageAccountName)."
            }
        }
    }
}