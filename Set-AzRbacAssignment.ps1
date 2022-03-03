
Import-Csv 'C:\Temp\RBAC.csv' | foreach-object {

    $adGroupName = $_.adGroupName
    $role = $_.role
    $scope = $_.scope

    switch ($scope) {
        root { 

            $ssSub = Get-AzSubscription | Where-Object -Filter { $_.Id -eq '' }
            Set-AzContext -SubscriptionId $ssSub.Id
            
            $provider = '/providers/Microsoft.Management/'
            $objectID = (Get-AzADGroup -DisplayName $adGroupName).Id

            New-AzRoleAssignment -RoleDefinitionName $role -Scope $provider -ObjectId $objectID
        }

        devtest { 

            $devTestSub = Get-AzSubscription | Where-Object -Filter { $_.Id -eq '' }
            Set-AzContext -SubscriptionId $devTestSub.Id
            
            $provider = '/providers/Microsoft.Management/managementGroups/'
            $objectID = (Get-AzADGroup -DisplayName $adGroupName).Id
    
            New-AzRoleAssignment -RoleDefinitionName $role -Scope $provider -ObjectId $objectID
        }

        prod { 

            $prodSub = Get-AzSubscription | Where-Object -Filter { $_.Id -eq '' }
            Set-AzContext -SubscriptionId $prodSub.Id
            
            $provider = '/providers/Microsoft.Management/managementGroups/'
            $objectID = (Get-AzADGroup -DisplayName $adGroupName).Id
        
            New-AzRoleAssignment -RoleDefinitionName $role -Scope $provider -ObjectId $objectID
        }

        RBACRoot { 

            $devTestSub = Get-AzSubscription | Where-Object -Filter { $_.Id -eq '' }
            Set-AzContext -SubscriptionId $devTestSub.Id
            
            $provider = '/providers/Microsoft.Management/managementGroups/'
            $objectID = (Get-AzADGroup -DisplayName $adGroupName).Id
    
            New-AzRoleAssignment -RoleDefinitionName $role -Scope $provider -ObjectId $objectID
        }

    }

}