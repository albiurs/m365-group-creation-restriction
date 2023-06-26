##########
# Microsoft 365 - restrict group creation for unpriviledged users
# 
# Requirements:
# 1. Create a secutriy group e.g. "SecurityMgmtStaff" in the M365 Admin Center
# 2. AzureADPreview PowerShell module installed:
#    https://www.powershellgallery.com/packages/AzureADPreview/
#
# Documetnation:
# https://learn.microsoft.com/de-DE/microsoft-365/solutions/manage-creation-of-groups?view=o365-worldwide
##########




# Variables
###########
$GroupName = "SecurityMgmtStaff"              # The name of the group for which the settings are being configured
$AllowGroupCreation = $False                  # Flag indicating whether group creation is allowed or not




# Getting AAD access
####################

# Connect to Azure Active Directory
Connect-AzureAD

# Quietly set execution policy to get full execution rights for follwing commands
Set-ExecutionPolicy Bypass -scope Process -Force -Confirm:$False




# Update groups and settings
############################

# Retrieve the ID of the existing group settings object for "Group.Unified" if it exists
$settingsObjectID = (Get-AzureADDirectorySetting | Where-object -Property Displayname -Value "Group.Unified" -EQ).id

# If the settings object doesn't exist, create a new one based on the template
if(!$settingsObjectID)
{
    $template = Get-AzureADDirectorySettingTemplate | Where-object {$_.displayname -eq "group.unified"}
    $settingsCopy = $template.CreateDirectorySetting()
    New-AzureADDirectorySetting -DirectorySetting $settingsCopy
    $settingsObjectID = (Get-AzureADDirectorySetting | Where-object -Property Displayname -Value "Group.Unified" -EQ).id
}

$settingsCopy = Get-AzureADDirectorySetting -Id $settingsObjectID

# Set the group creation flag based on the provided value
$settingsCopy["EnableGroupCreation"] = $AllowGroupCreation

# If a group name is provided, set the _allowed_ group ID
if($GroupName)
{
    $settingsCopy["GroupCreationAllowedGroupId"] = (Get-AzureADGroup -SearchString $GroupName).objectid
} else {  # If no group name is provided, set the allowed group ID to the provided value (which could be a group ID or empty)
    $settingsCopy["GroupCreationAllowedGroupId"] = $GroupName
}

# Update the settings object with the modified values
Set-AzureADDirectorySetting -Id $settingsObjectID -DirectorySetting $settingsCopy

# Retrieve and output the current values of the settings object
(Get-AzureADDirectorySetting -Id $settingsObjectID).Values