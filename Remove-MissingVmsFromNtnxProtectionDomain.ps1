# Remove-MissingVmsFromNtnxProtectionDomain.ps1
# Author: Michael Nichols
# Use at own risk - this script is provided for illustrative purposes
# Version .1
# Purpose: Gets VMs listed in Nutanix alert 'Protected Vms not found', removes VMs from specific Protection Domain, and closes alert
# This code presents reactive remediation
# Example Code
$ArrayNtxClusters = "cluster1", "cluster2", "cluster3"
$AdminName = 'adminuser'

# Create a secure string password - note that I do not endorse storing passwords in scripts - having the plaintext password below is for simplicity
$Password = 'P@ssW0rD!'
$Secure_String_Pwd = ConvertTo-SecureString $Password -AsPlainText -Force

Add-PSSnapIn NutanixCmdletsPSSnapin

$ArrayNtxClusters | ForEach-Object {
  
  Connect-NTNXCluster -Server $_ -UserName $AdminName -Password $Secure_String_Pwd -AcceptInvalidSSLCerts -ForcedConnection | Out-Null
  
  Get-NtnxAlert | where {$_.resolved -eq $false} | where {$_.alerttitle -eq 'Protected Vms not found'} | Select contextvalues | foreach {
    $ProtectionDomain = $_.contextvalues[0]
    $MissingVms = $_.contextvalues[1]
    $MissingVms = $MissingVms.Replace(" ","")
    $ArrayMissingVms = $MissingVms.Split(",")
    if ($ArrayMissingVMs -match '...') {$ArrayMissingVms=$ArrayMissingVms[0..($ArrayMissingVms.Length-2)]}
    Remove-NTNXProtectionDomainVM -pdname $ProtectionDomain -inputlist $ArrayMissingVms -ErrorAction SilentlyContinue
  }
Get-NTNXAlert | where {$_.resolved -eq $false} | where {$_.alerttitle -eq 'Protect VMs not found'} | Resolve-NTNXAlert
Disconnect-NTNXCluster *
}












