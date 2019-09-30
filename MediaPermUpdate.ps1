<#
.SYNOPSIS
  Update user rights for external USB media

.DESCRIPTION
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

.INPUTS
  confirm with user to update the user permissions

.OUTPUTS
  Log file stored in C:\Temp\MediaPermUpdate.log>
.NOTES
  Version:        1.0
  Author:         Nirmala 
  Creation Date:  July 2, 2019
  Purpose/Change: Script development
  
.EXAMPLE
 
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Silently Continue
$ErrorActionPreference = "SilentlyContinue"

#Dot Source required Function Libraries
#none

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Script Version
$ScriptVersion = "1.0"

#Log File Info
$LogPath = "C:\Temp"
$LogName = "MediaPermUpdate.log"
$LogFilePath = Join-Path -Path $LogPath -ChildPath $LogName
$USBpath = Get-WmiObject Win32_Volume -Filter "DriveType='2'" | Select-Object Name

$flag = "False"
$scriptFlag = "False"
$errorMessage = ""

#variable for permissions

$UserList = [ordered]@{"Everyone" = "ReadAndExecute"
"$env:USERDOMAIN\$env:USERNAME" = "FullControl"
"SYSTEM" = "FullControl"
}

#-----------------------------------------------------------[Functions]------------------------------------------------------------



function Write-Log 
{
    param 
    (
        [Parameter(Mandatory=$False, Position=0)][String]$Entry
    )

    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') $Entry" | Out-File -FilePath $LogFilePath  -Append
}

Function Lock-User
{
    param 
    (
        [Parameter(Mandatory=$True, Position=0)][String]$UserName,
        [Parameter(Mandatory=$True, Position=1)][String]$Rights,
        [Parameter(Mandatory=$True, Position=2)][String]$Path
    )
    Begin
    {
        Write-Log -Entry "Setting up permissions for $UserName on $Path..."
        Write-Log
    }
  
    Process
    {
        Try
        {
               
            $objUser = New-Object System.Security.Principal.NTAccount($UserName)
            $rule = new-object System.Security.AccessControl.FileSystemAccessRule($objUser,
            $Rights,@("ObjectInherit","ContainerInherit"),"None","Allow")
            $NewPath = Join-Path -Path $Path -ChildPath "*"
            $acl = Get-ACL -Path $Path
            #Set-Variable -name "$ruleFlag" -Value True



            $acl.SetAccessRule($rule) 
            Write-Host "Setting-up permission for user: $UserName on $Path..."
            (Get-Item $Path).SetAccessControl($acl)
            $flag = "True"
            Write-Host "Permissions set successfully for User: $UserName on $Path" 
        
        }
    
        Catch
        {
            $errorMessage = $_.Exception.Message
            Write-Host $errorMessage
            Write-Log $errorMessage
            $flag = "False"
            break
        }
    }
  
    End
    {
        If($flag -eq "True")
        {
            
            Write-Log "Permissions set successfully for User: $UserName on $Path."
        }
        Else
        {
            Write-Log -Entry "Error in setting up permissions for User: $UserName on $Path"
        }
    }
}


Function Unlock-User
{
    param 
    (
        [Parameter(Mandatory=$True, Position=0)][String]$UserName,
        [Parameter(Mandatory=$True, Position=1)][String]$Rights,
        [Parameter(Mandatory=$True, Position=2)][String]$Path
    )
    Begin
    {
        Write-Log -Entry "Resetting permissions for $UserName on $Path..."
        Write-Log
    }
  
    Process
    {
        Try
        {
               
            $objUser = New-Object System.Security.Principal.NTAccount($UserName)
            $rule = new-object System.Security.AccessControl.FileSystemAccessRule($objUser,
            $Rights,@("ObjectInherit","ContainerInherit"),"None","Allow")
            $acl = Get-ACL -Path $Path 


            if($UserName -eq "Everyone")
            {
                $rule = new-object System.Security.AccessControl.FileSystemAccessRule($objUser,
                "FullControl",@("ObjectInherit","ContainerInherit"),"None","Allow")
                $acl.SetAccessRule($rule) 
                Write-Host "Resetting permissions for $UserName on $Path..."
                (Get-Item $Path).SetAccessControl($acl)

                $flag = "True" 
                Write-Host "Permissions reset successful for User: $UserName on $Path." 
                $acl.SetOwner($objUser)

            }
            else
            {
                $acl.RemoveAccessRule($rule) 
                Write-Host "Resetting permissions for user: $UserName on $Path"
                #Set-ACL -Path $Path -AclObject $acl -ErrorAction Stop
                (Get-Item $Path).SetAccessControl($acl)
                $flag ="True"
                Write-Host "Permissions reset successful for User: $UserName on $Path." 
            }
        }
    
        Catch
        {
            $errorMessage = $_.Exception.Message
            Write-Host $errorMessage
            Write-Log $errorMessage
            $flag = "False"
            break
        }
    }
  
    End
    {
        If($flag -eq "True")
        {
            Write-Log -Entry "Permissions reset successful for User: $UserName on $Path."
        }
        Else
        {
            Write-Log -Entry "Error in resetting permissions."
        }
    }
}




Function Update-Permissions
{
    
    Param
    (
        [Parameter(Mandatory=$true)] [string]$Mode  
    )
    Begin
    {
        Write-Log -Entry "Script started"
    }
  
    Process
    {
        Try
        {
            #Read the drive for external Media      
            if($USBpath.Count -gt 1) 
            {
                Write-host "Too many USB drives found. Please keep only MIApps media."
                exit 1
            }
            elseif($USBpath.Count -eq 0) 
            {
                Write-host "Please insert the MIApps media."
                exit 1
            }
            else
            {
                Write-host "External Media found on $($USBpath.Name)"
                $confirmation = Read-Host "Are you Sure You Want To Proceed:"
                if (($confirmation -eq 'y') -and ($Mode.ToUpper() -eq "LOCK")) 
                {
                    foreach($key in $UserList.Keys)
                    {
                        Lock-User -UserName $key -Rights $UserList[$key] -Path $USBpath.Name
                        $scriptFlag = "True"
                        
                    }
                }
                elseif (($confirmation -eq 'y') -and ($Mode.ToUpper() -eq "UNLOCK")) 
                {
                    foreach($key in $UserList.Keys)
                    {
                        Unlock-User -UserName $key -Rights $UserList[$key] -Path $USBpath.Name
                        $scriptFlag = "True"
                    }
                }
                else
                {
                    exit 0
                }
                    
            }
            
        }
    
        Catch
        {
            $errorMessage = $_.Exception.Message
            Write-Host $errorMessage
            Write-Log $errorMessage
            $scriptFlag = "False"
            break
            
        }
    }
  
    End
    {
        If($scriptFlag -eq "True")
        {
            Write-Log -Entry "Script executed successfully"
        }
        Else
        {
            Write-Log -Entry "Script Failed"
        }
    }
  
 }

 

#-----------------------------------------------------------[Execution]------------------------------------------------------------

Write-Log "Script Log started. Script Version: $ScriptVersion"
#Script Execution

Update-Permissions

Write-Log "Script Log Finished Script Version: $ScriptVersion"