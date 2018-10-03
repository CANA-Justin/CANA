<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.154
	 Created on:   	10/03/2018 11:26 AM
	 Created by:   	Justin Holmes
	 Organization: 	CANA Limited
	 Filename:     	SetADPicture.ps1
	===========================================================================
	.DESCRIPTION
		This file, in conjenction with a registry security change will set the logged on users AD profile picture to be the Windows 10 User pictures.
		This script runs at logoff (because the users profile needs to exist on the computer first; First time login).
		More information can be found at http://woshub.com/how-to-set-windows-user-account-picture-from-active-directory/
#>
[CmdletBinding(SupportsShouldProcess = $true)]
Param ()
function Test-Null($InputObject) { return !([bool]$InputObject) }
$ADuser = ([ADSISearcher]"(&(objectCategory=User)(SAMAccountName=$env:username))").FindOne().Properties
$ADuser_photo = $ADuser.thumbnailphoto
$ADuser_sid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
If ((Test-Null $ADuser_photo) -eq $false)
{
	$img_sizes = @(32, 40, 48, 96, 192, 200, 240, 448)
	$img_mask = "Image{0}.jpg"
	$img_base = "C:\ProgramData\AccountPictures"
	$reg_base = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AccountPicture\Users\{0}"
	$reg_key = [string]::format($reg_base, $ADuser_sid)
	$reg_value_mask = "Image{0}"
	If ((Test-Path -Path $reg_key) -eq $false) { New-Item -Path $reg_key }
	Try
	{
		ForEach ($size in $img_sizes)
		{
			$dir = $img_base + "\" + $ADuser_sid
			If ((Test-Path -Path $dir) -eq $false) { $(mkdir $dir).Attributes = "Hidden" }
			$file_name = ([string]::format($img_mask, $size))
			$path = $dir + "\" + $file_name
			Write-Verbose " saving: $file_name"
			$ADuser_photo | Set-Content -Path $path -Encoding Byte -Force
			$name = [string]::format($reg_value_mask, $size)
			$value = New-ItemProperty -Path $reg_key -Name $name -Value $path -Force
		}
	}
	Catch
	{
		Write-Error "Check permissions to files or registry."
	}
}

