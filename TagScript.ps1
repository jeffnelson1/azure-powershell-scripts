#Login to Azure
#Connect-AzAccount

#List all Resources within the Subscription
$Resources = Get-AzResource

#For each Resource apply the Tag of the Resource Group
Foreach ($resource in $Resources)
{
    $Rgname = $resource.Resourcegroupname

    $resourceid = $resource.resourceId
    $RGTags = (Get-AzResourceGroup -Name $Rgname).Tags

    $resourcetags = $resource.Tags

    If ($resourcetags -eq $null)
        {
            Write-Output "---------------------------------------------"
            Write-Output "Applying the following Tags to $($resourceid)" $RGTags
            Write-Output "---------------------------------------------"
            $Settag = Set-AzResource -ResourceId $resourceid -Tag $RGTagS -Force
            
        }
    Else
        {
            $RGTagFinal = @{}
            $RGTagFinal = $RGTags                  
                    Foreach ($resourcetag in $resourcetags.GetEnumerator())
                    {
                
                    If ($RGTags.Keys -inotcontains $resourcetag.Key)
                        {                        
                                Write-Output "------------------------------------------------"
                                Write-Output "Keydoesn't exist in RG Tags adding to Hash Table" $resourcetag
                                Write-Output "------------------------------------------------"
                                $RGTagFinal.Add($resourcetag.Key,$resourcetag.Value)
                        }    

                    }
            Write-Output "---------------------------------------------"
            Write-Output "Applying the following Tags to $($resourceid)" $RGTagFinal
            Write-Output "---------------------------------------------"
            $Settag = Set-AzResource -ResourceId $resourceid -Tag $RGTagFinal -Force
        }   
}