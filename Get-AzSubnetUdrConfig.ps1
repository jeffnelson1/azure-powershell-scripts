$subs = @( "subid"
)

foreach ($sub in $subs) {

    $subscriptionName = (Get-AzSubscription -SubscriptionId $sub).Name
    Write-Output "Setting context to $subscriptionName"
    Set-AzContext -SubscriptionId $sub
    $vNets = Get-AzVirtualNetwork

    foreach ($vNet in $vNets) {
    
        Write-Output "Getting subnet data from vNet - $($vNet.Name)"
        $subnets = $vNet.subnets

        foreach ($subnet in $subnets) {

            Write-Output "Getting UDR data from subnet - $($subnet.Name)"
            $vNetName = $subnet.Id.Split("/")[-3]
            $subnetName = $subnet.Name
            $routeTable = $subnet.RouteTable.Id

            if ($null -ne $routeTable) {
            
            $routeTable = $routeTable.Split("/")[-1]
            }

            else {
            $routeTable = "Not Configured"
            }
        
            $obj = New-Object PSObject -Property @{
                 vNet          = $vNetName
                 Subnet        = $subnetName
                 Route_Table   = $routeTable
                 Region        = $vNet.Location
                 Subscription  = $subscriptionName
            }

        ## Change the path to a valid path on the system that you're running the script from
        $obj | Select-Object vNet, Subnet, Route_Table, Region, Subscription | export-CSV 'C:\Temp\udrReport.csv' -Append

        }

    }
}




    


