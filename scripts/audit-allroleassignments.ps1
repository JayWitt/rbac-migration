<#
.SYNOPSIS
    Lists all role assignments for all subscriptions a user has access to within an identified AAD tenant.
.DESCRIPTION
    TBD 
#>

# Objects and custom roles
$objectNamesDict = @{}
$customRoles = New-Object System.Collections.ArrayList

function Get-RoleAssignments {
    $subscriptionId = (Get-AzContext).Subscription.Id
    Write-Host "Checking ${subscriptionId}"
    $roleAssignments = Get-AzRoleAssignment

    foreach ($assignment in $roleAssignments) {
    
        $objectName = ""
    
        # Check if the object name exists int the dictionary. If not, add it.
        if ($objectNamesDict.ContainsKey($assignment.ObjectId)) {
            $objectName = $objectNamesDict[$assignment.ObjectId]
        }
        else {
            if ($assignment.ObjectType -eq "User") {
                $aadObject = Get-AzADUser -ObjectId $assignment.ObjectId
                $objectName = $aadObject.DisplayName
            }
            if ($assignment.ObjectType -eq "Group") {
                $aadObject = Get-AzADGroup -ObjectId $assignment.ObjectId
                $objectName = $aadObject.DisplayName    
            }
            if ($assignment.ObjectType -eq "ServicePrincipal") {
                $aadObject = Get-AzADServicePrincipal -ObjectId $assignment.ObjectId
                $objectName = $aadObject.DisplayName
            }
    
            $objectNamesDict.Add($assignment.ObjectId, $objectName)
        }
    
        $customRole = @{
            Subscription = (Get-AzContext).Subscription.Name
            Scope = $assignment.Scope
            DisplayName = $assignment.DisplayName
            SignInName = $assignment.SignInName
            RoleDefinitionName = $assignment.RoleDefinitionName
            RoleDefinitionId = $assignment.RoleDefinitionId
            ObjectId = $assignment.ObjectId
            ObjectName = $objectName
            ObjectType = $assignment.ObjectType
            CanDelegate = $assignment.CanDelegate
            Description = $assignment.Description
            ConditionVersion = $assignment.ConditionVersion
            Condition = $assignment.Condition
        }
    
        $customRoles.Add($customRole)
    }
}

$tenantId = ""
Connect-AzAccount -Tenant $tenantId
$azContexts = get-Azcontext -listavailable

foreach ($context in $azContexts) {
    if ($context.Subscription.TenantId -eq $tenantId) {
        $id = $context.Subscription.Id
        $subscriptionName = ($context).Subscription.Name
        Write-Host "Connecting to: $subscriptionName"
        Set-AzContext -Subscription $id -ErrorAction SilentlyContinue -WarningVariable connectionWarning -ErrorVariable connectionError
        $result = Get-RoleAssignments
    }
}

$outputFileName = "report.csv"
$folderName = "data"
if (!(test-path $folderName))
{
      New-Item -ItemType Directory -Force -Path $folderName
}

$customRoles | ForEach-Object { New-Object PSObject -Property $_ } | Export-Csv "${folderName}/${outputFileName}"