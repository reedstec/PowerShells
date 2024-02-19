# Define the root folder path
$folderPath = Read-Host "Enter the directory path"

# Specify the account (Domain Admins in this case) and permissions
$account = "Domain\Domain Admins"
$permissions = "FullControl"

# Get the folder object
$folder = Get-Item -LiteralPath $folderPath

# Create an Access Control Entry (ACE) for the specified account and permissions
$ace = New-Object System.Security.AccessControl.FileSystemAccessRule($account, $permissions, "ContainerInherit, ObjectInherit", "None", "Allow")

# Get the current access control list (ACL) of the folder
$acl = $folder.GetAccessControl()

# Add the ACE to the ACL
$acl.AddAccessRule($ace)

# Apply the modified ACL to the folder
Set-Acl -Path $folderPath -AclObject $acl

Write-Host "Permissions updated for $account on $folderPath"
