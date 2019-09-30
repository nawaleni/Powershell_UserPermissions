# Powershell_UserPermissions
 Update user rights for external USB media.
  'Lock' mode:
  1) Create a logged in user with 'Full Control' permissions
  2) Create user 'SYSTEM' with 'Full Control' persmissions
  3) Sets permission of user 'Everyone' to 'Read and execute'
  'Unlock' mode:
  1) Gives 'Everyone' full control access
  2) Removes access of logged in user and 'SYSTEM' 

.PARAMETER <Parameter_Name>
    Script takes input paramter - 
    Values: 
    lock: script will update the rights of the system
    unlock: Assigns 'Everyone' with 'Full Control access'
